package;

import haxe.Json;
#if WebP
import webp.WebP;
#end
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets as LimeAssets;

class Paths
{
	public static final SOUND_EXT = #if web "mp3" #else "ogg" #end;
	private static final PRELOAD_LIBRARY = "preload";
	private static final CLOWN_LIBRARY = "clown";

	private static var currentLevel:String;
	public static var useModAssets:Bool = true;

	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	private static function formatPath(library:String, file:String)
		return '$library:assets/$library/$file';

	private static function formatPreloadPath(file:String)
		return 'assets/$file';

	public static function getAsset(path:String, type:AssetType, ?library:String):String
	{
		if (library == CLOWN_LIBRARY)
			return getClownPath(path);

		return getPath(path, type, library);
	}

	static function getModPath(file:String):String
	{
		if (!useModAssets)
			return null;
		return ModManager.getAsset(file);
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		var modPath = getModPath(file);
		if (modPath != null)
			return modPath;

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

	inline static function getClownPath(file:String) // for some reason it doenst get the 'clown' library???
		return getLibraryPathForce(file, 'clown');

	inline static function getPreloadPath(file:String)
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	public static function loadJson(key:String, ?library:String):Dynamic
	{
		var path = json(key, library);
		if (LimeAssets.exists(path))
		{
			var content = LimeAssets.getText(path);
			try
			{
				return Json.parse(content.trim());
			}
			catch (error:Dynamic)
			{
				trace('Error parsing JSON from ' + path + ': ' + Std.string(error));
				return null;
			}
		}
		return null;
	}

	static public function sound(key:String, ?library:String)
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String)
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);

	inline static public function voices(song:String, diff:String = '')
		return 'songs:assets/songs/${song.toLowerCase()}/Voices${diff.toLowerCase()}.$SOUND_EXT';

	inline static public function inst(song:String, diff:String = '')
		return 'songs:assets/songs/${song.toLowerCase()}/Inst${diff.toLowerCase()}.$SOUND_EXT';

	inline static public function image(key:String, ?library:String):Dynamic
	{
		var cachedGraphic = CachedFrames.get(key);
		if (cachedGraphic != null)
			return cachedGraphic;

		#if WebP
		var webpPath:String = getPath('images/$key.webp', IMAGE, library);
		if (OpenFlAssets.exists(webpPath, IMAGE))
			return WebP.getBitmapData(webpPath.split(":")[1]);
		#end

		var path = getPath('images/$key.png', IMAGE, library);
		return path;
	}

	inline static public function font(key:String)
		return 'assets/fonts/$key';

	inline static public function getSparrowAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));

	inline static public function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));

	public static function getCharacterData(char:String):Dynamic
	{
		var jsonPath = 'characters/$char';
		var scriptData = getCharacterScript(char);

		return {
			config: loadJson(jsonPath),
			script: scriptData != null ? scriptData.content : null
		};
	}

	public static function exists(key:String):Bool
	{
		var path = getPath(key, TEXT, 'preload');
		return LimeAssets.exists(path);
	}

	public static function getText(key:String):String
	{
		var path = getPath(key, TEXT, 'preload');
		return LimeAssets.getText(path);
	}

	public static function getScriptPath(key:String, ?type:String):String
	{
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
				var songPath = 'data/songs/${key.toLowerCase()}/script.hx';
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
			return {
				path: scriptPath,
				content: getText(scriptPath),
				type: type,
				name: key
			};
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

	public static function loadFile(path:String):String
	{
		var modPath = getModPath(path);
		if (modPath != null)
		{
			return sys.io.File.getContent(modPath);
		}
		return null;
	}

	public static function loadBytes(path:String):haxe.io.Bytes
	{
		var modPath = getModPath(path);
		if (modPath != null)
		{
			return sys.io.File.getBytes(modPath);
		}
		return null;
	}
}

typedef ScriptData =
{
	var path:String;
	var content:String;
	var type:Null<String>;
	var name:String;
}
