package;

import haxe.Json;
#if WebP
import webp.WebP;
#end
import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets as LimeAssets;
import haxe.io.Path;

using StringTools;

/**
 * Handles asset loading from both mods and base game.
 * Priority: Mods -> Base Game -> Libraries
 */
class Paths
{
	public static final SOUND_EXT = #if web "mp3" #else "ogg" #end;
	private static final PRELOAD_LIBRARY = "preload";
	private static final CLOWN_LIBRARY = "clown";

	inline public static var MODS_FOLDER:String = "mods";
	public static var currentModDirectory:String = null;
	public static var ignoreModFolders:Array<String> = [
		'data',
		'characters',
		'images',
		'scripts',
		'songs',
		'sounds',
		'music',
		'videos',
		'fonts'
	];

	private static var pathCache:Map<String, String> = new Map<String, String>();
	private static var assetsCache:Map<String, Dynamic> = new Map<String, Dynamic>();

	private static var currentLevel:String;
	public static var useModAssets:Bool = true;

	public static var enabledMods:Array<String> = [];
	private static var modPriorities:Map<String, Int> = new Map<String, Int>();

	public static function init()
	{
		if (ModManager.initialized)
		{
			enabledMods = ModManager.activeMods.map(mod -> mod.name);

			modPriorities.clear();
			for (mod in ModManager.activeMods)
			{
				var priority = mod.loadPriority != null ? mod.loadPriority : 0;
				modPriorities.set(mod.name, priority);
			}
		}
		else
			reloadModsConfig();
	}

	public static function reloadModsConfig()
	{
		enabledMods = [];
		modPriorities = new Map<String, Int>();

		if (FileSystem.exists('$MODS_FOLDER/modList.txt'))
		{
			var modsListText:String = File.getContent('$MODS_FOLDER/modList.txt');
			var modsList:Array<String> = modsListText.split('\n');

			for (i in 0...modsList.length)
			{
				var mod:String = modsList[i].trim();
				if (mod.length > 0 && FileSystem.exists('$MODS_FOLDER/$mod') && FileSystem.isDirectory('$MODS_FOLDER/$mod'))
				{
					enabledMods.push(mod);
					modPriorities.set(mod, modsList.length - i);
					trace('Mod loaded: $mod (priority: ${modPriorities.get(mod)})');
				}
			}
		}

		clearCache();
	}

	public static function clearCache()
	{
		pathCache.clear();
		assetsCache.clear();
		OpenFlAssets.cache.clear();
	}

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function exists(key:String, ?type:AssetType = null, ?checkMods:Bool = true):Bool
	{
		if (checkMods && useModAssets)
		{
			var modPath = getModPath(key);
			if (modPath != null)
				return true;
		}

		var path = getPath(key, type, null);
		if (OpenFlAssets.exists(path, type))
			return true;

		if (key.indexOf(':') > -1)
		{
			var library = key.substring(0, key.indexOf(':'));
			var fileName = key.substring(key.indexOf(':') + 1);
			return OpenFlAssets.exists('$library:assets/$library/$fileName', type);
		}

		return false;
	}

	public static function getText(key:String):String
	{
		if (useModAssets)
		{
			var modPath = getModFilePath(key);
			if (modPath != null && FileSystem.exists(modPath))
				return File.getContent(modPath);
		}

		var path = getPath(key, TEXT, null);
		if (OpenFlAssets.exists(path, TEXT))
			return LimeAssets.getText(path);

		trace('Text file not found: $key');
		return null;
	}

	public static function getModPath(file:String):String
	{
		if (!useModAssets)
			return null;

		if (ModManager == null)
		{
			trace("Warning: ModManager not initialized");
			return null;
		}

		var modAsset = ModManager.getAsset(file);
		if (modAsset != null)
			return modAsset;

		var cleanFile = cleanFilePath(file);

		if (pathCache.exists('MOD:$cleanFile'))
			return pathCache.get('MOD:$cleanFile');

		var modsOrdered = enabledMods.copy();
		modsOrdered.sort((a, b) -> modPriorities.get(b) - modPriorities.get(a));

		if (currentModDirectory != null && !modsOrdered.contains(currentModDirectory))
			modsOrdered.unshift(currentModDirectory);

		for (mod in modsOrdered)
		{
			var modFilePath = '$MODS_FOLDER/$mod/$cleanFile';
			if (FileSystem.exists(modFilePath))
			{
				pathCache.set('MOD:$cleanFile', modFilePath);
				return modFilePath;
			}
		}

		return null;
	}

	private static function getModFilePath(file:String):String
	{
		var modPath = getModPath(file);
		if (modPath != null)
			return modPath;

		var path = 'assets/$file';
		if (FileSystem.exists(path))
			return path;

		return null;
	}

	public static function cleanFilePath(path:String):String
	{
		if (path == null)
			return null;

		var prefixesToRemove = ['assets/', 'assets\\'];
		for (prefix in prefixesToRemove)
		{
			if (path.startsWith(prefix))
				path = path.substr(prefix.length);
		}

		path = path.replace('\\', '/');

		return path;
	}

	public static function getFileBytes(filePath:String):haxe.io.Bytes
	{
		var modPath = getModFilePath(filePath);
		if (modPath != null)
			return File.getBytes(modPath);

		var path = getPath(filePath, BINARY, null);
		if (OpenFlAssets.exists(path, BINARY))
			return LimeAssets.getBytes(path);

		trace('Arquivo não encontrado: $filePath');
		return null;
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library == 'clown')
			return getClownPath(file);

		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, 'shared');
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	inline static public function clowntxt(key:String)
		return getClownPath('data/$key.txt');

	inline static function getClownPath(file:String)
		return getLibraryPathForce(file, 'clown');

	inline static function getPreloadPath(file:String)
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		var modPath = getModPath(file);
		if (modPath != null)
			return modPath;

		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		var modPath = getModPath('data/$key.txt');
		if (modPath != null)
			return modPath;

		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		var modPath = getModPath('data/$key.xml');
		if (modPath != null)
			return modPath;

		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		var modPath = getModPath('data/$key.json');
		if (modPath != null)
			return modPath;

		return getPath('data/$key.json', TEXT, library);
	}

	public static function loadJson(key:String, ?library:String):Dynamic
	{
		var modPath = getModPath('data/$key.json');
		var content:String = null;

		if (modPath != null)
			content = File.getContent(modPath);
		else
		{
			var path = json(key, library);
			if (LimeAssets.exists(path))
				content = LimeAssets.getText(path);
		}

		if (content != null)
		{
			try
			{
				return Json.parse(content.trim());
			}
			catch (error:Dynamic)
			{
				trace('Error parsing JSON from $key: $error');
				return null;
			}
		}
		return null;
	}

	static public function sound(key:String, ?library:String)
	{
		var modPath = getModPath('sounds/$key.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String)
	{
		var modPath = getModPath('music/$key.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String, diff:String = '')
	{
		// Verificar mods primeiro
		var modPath = getModPath('songs/${song.toLowerCase()}/Voices${diff.toLowerCase()}.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		return 'songs:assets/songs/${song.toLowerCase()}/Voices${diff.toLowerCase()}.$SOUND_EXT';
	}

	inline static public function inst(song:String, diff:String = '')
	{
		var modPath = getModPath('songs/${song.toLowerCase()}/Inst${diff.toLowerCase()}.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		return 'songs:assets/songs/${song.toLowerCase()}/Inst${diff.toLowerCase()}.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String):Dynamic
	{
		var cachedGraphic = CachedFrames.get(key);
		if (cachedGraphic != null)
			return cachedGraphic;

		var modPathWebp = getModPath('images/$key.webp');
		if (modPathWebp != null)
		{
			#if WebP
			return WebP.getBitmapData(modPathWebp);
			#end
		}

		var modPathPng = getModPath('images/$key.png');
		if (modPathPng != null)
			return modPathPng;

		#if WebP
		var webpPath:String = getPath('images/$key.webp', IMAGE, library);
		if (OpenFlAssets.exists(webpPath, IMAGE))
			return WebP.getBitmapData(webpPath.split(":")[1]);
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		return path;
	}

	inline static public function font(key:String)
	{
		var modPath = getModPath('fonts/$key');
		if (modPath != null)
			return modPath;

		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		var modPathXml = getModPath('images/$key.xml');
		var modPathPng = getModPath('images/$key.png');

		if (modPathXml != null && modPathPng != null)
			return FlxAtlasFrames.fromSparrow(modPathPng, File.getContent(modPathXml));

		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		var modPathTxt = getModPath('images/$key.txt');
		var modPathPng = getModPath('images/$key.png');

		if (modPathTxt != null && modPathPng != null)
			return FlxAtlasFrames.fromSpriteSheetPacker(modPathPng, File.getContent(modPathTxt));

		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	public static function getCharacterData(char:String):Dynamic
	{
		var jsonPath = 'characters/$char';
		var scriptData = getCharacterScript(char);

		return {
			config: loadJson(jsonPath),
			script: scriptData != null ? scriptData.content : null
		};
	}

	public static function getScriptPath(key:String, ?type:String):String
	{
		var modScriptPath = null;

		switch (type)
		{
			case "character":
				modScriptPath = getModPath('data/characters/$key.hx');
				if (modScriptPath != null)
					return modScriptPath;

			case "song":
				modScriptPath = getModPath('data/${key.toLowerCase()}/script.hx');
				if (modScriptPath != null)
					return modScriptPath;

			default:
				modScriptPath = getModPath('data/scripts/$key.hx');
				if (modScriptPath != null)
					return modScriptPath;
		}

		var preloadPath = 'data/scripts/$key.hx';
		if (exists(preloadPath))
			return preloadPath;

		switch (type)
		{
			case "character":
				var charPath = 'data/characters/$key.hx';
				if (exists(charPath))
					return charPath;

			case "song":
				var songPath = 'data/${key.toLowerCase()}/script.hx';
				if (exists(songPath))
					return songPath;
		}

		return null;
	}

	public static function getScript(key:String, ?type:String):ScriptData
	{
		var scriptPath = getScriptPath(key, type);
		if (scriptPath != null)
		{
			var content = null;

			if (scriptPath.startsWith(MODS_FOLDER))
			{
				if (FileSystem.exists(scriptPath))
					content = File.getContent(scriptPath);
			}
			else
			{
				content = getText(scriptPath);
			}

			if (content != null)
			{
				return {
					path: scriptPath,
					content: content,
					type: type,
					name: key
				};
			}
		}
		return null;
	}

	public static function getSongScript(song:String):ScriptData
	{
		return getScript(song, "song");
	}

	public static function getCharacterScript(char:String):ScriptData
	{
		return getScript(char, "character");
	}

	public static function getCustomScript(name:String):ScriptData
	{
		return getScript(name);
	}

	public static function getLibraryPathForFile(file:String):String
	{
		var path:String = getModPath(file);
		if (path != null)
			return path;

		for (library in ["preload", "default", "shared"])
		{
			path = getLibraryPath(file, library);
			if (OpenFlAssets.exists(path, null))
				return path;
		}

		return getPreloadPath(file);
	}

	public static function directoryExists(path:String):Bool
	{
		if (useModAssets)
		{
			for (mod in enabledMods)
			{
				var modDirPath = '$MODS_FOLDER/$mod/$path';
				if (FileSystem.exists(modDirPath) && FileSystem.isDirectory(modDirPath))
					return true;
			}
		}

		var assetPath = 'assets/$path';
		return FileSystem.exists(assetPath) && FileSystem.isDirectory(assetPath);
	}

	public static function listFiles(directory:String, ?filter:String->Bool = null):Array<String>
	{
		var files:Array<String> = [];
		var seenFiles:Map<String, Bool> = new Map();

		if (useModAssets)
		{
			for (mod in enabledMods)
			{
				var modDirPath = '$MODS_FOLDER/$mod/$directory';
				try
				{
					if (FileSystem.exists(modDirPath) && FileSystem.isDirectory(modDirPath))
					{
						for (file in FileSystem.readDirectory(modDirPath))
						{
							try
							{
								if (FileSystem.isDirectory('$modDirPath/$file'))
									continue;

								if (!seenFiles.exists(file) && (filter == null || filter(file)))
								{
									seenFiles.set(file, true);
									files.push(file);
								}
							}
							catch (e)
							{
								trace('Error processing file $file in $modDirPath: $e');
							}
						}
					}
				}
				catch (e)
				{
					trace('Error reading directory $modDirPath: $e');
				}
			}
		}

		var assetPath = 'assets/$directory';
		if (FileSystem.exists(assetPath) && FileSystem.isDirectory(assetPath))
		{
			for (file in FileSystem.readDirectory(assetPath))
			{
				if (FileSystem.isDirectory('$assetPath/$file'))
					continue;

				if (!seenFiles.exists(file) && (filter == null || filter(file)))
				{
					seenFiles.set(file, true);
					files.push(file);
				}
			}
		}

		return files;
	}

	public static function listDirectories(directory:String):Array<String>
	{
		var directories:Array<String> = [];
		var seenDirs:Map<String, Bool> = new Map();

		if (useModAssets)
		{
			for (mod in enabledMods)
			{
				var modDirPath = '$MODS_FOLDER/$mod/$directory';
				if (FileSystem.exists(modDirPath) && FileSystem.isDirectory(modDirPath))
				{
					for (file in FileSystem.readDirectory(modDirPath))
					{
						if (FileSystem.isDirectory('$modDirPath/$file') && !seenDirs.exists(file) && !ignoreModFolders.contains(file))
						{
							seenDirs.set(file, true);
							directories.push(file);
						}
					}
				}
			}
		}

		var assetPath = 'assets/$directory';
		if (FileSystem.exists(assetPath) && FileSystem.isDirectory(assetPath))
		{
			for (file in FileSystem.readDirectory(assetPath))
			{
				if (FileSystem.isDirectory('$assetPath/$file') && !seenDirs.exists(file))
				{
					seenDirs.set(file, true);
					directories.push(file);
				}
			}
		}

		return directories;
	}

	/**
	 * Gets music file checking mods first
	 * @param key Music file name without extension
	 * @param library Optional library name
	 * @return Path to music file
	 */
	public static function getMusicPath(key:String, ?library:String):String
	{
		// Check mods first
		var modPath = getModPath('music/$key.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		// Then check base game
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	/**
	 * Gets sound file checking mods first
	 * @param key Sound file name without extension
	 * @param library Optional library name
	 * @return Path to sound file
	 */
	public static function getSoundPath(key:String, ?library:String):String
	{
		var modPath = getModPath('sounds/$key.$SOUND_EXT');
		if (modPath != null)
			return modPath;

		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}
}

typedef ScriptData =
{
	var path:String;
	var content:String;
	var type:Null<String>;
	var name:String;
}
