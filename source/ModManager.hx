package;

import scripting.ScriptManager;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;

using StringTools;

class ModManager
{
	public static var modsFolder:String = "mods/";
	public static var activeMods:Array<ModData> = [];
	public static var modAssets:Map<String, String> = new Map();
	public static var modScripts:Map<String, ScriptManager> = new Map();

	public static function init()
	{
		if (!FileSystem.exists(modsFolder))
			FileSystem.createDirectory(modsFolder);

		loadMods();
		initializeModScripts();
	}

	public static function loadMods()
	{
		activeMods = [];
		modAssets.clear();

		if (!FileSystem.exists(modsFolder))
			return;

		for (modFolder in FileSystem.readDirectory(modsFolder))
		{
			var modPath = '${modsFolder}${modFolder}';
			if (FileSystem.isDirectory(modPath))
			{
				loadMod(modPath);
			}
		}
	}

	static function loadMod(path:String)
	{
		var modConfigPath = '${path}/mod.json';
		if (!FileSystem.exists(modConfigPath))
			return;

		try
		{
			var modConfig:ModData = Json.parse(File.getContent(modConfigPath));
			modConfig.path = path;
			activeMods.push(modConfig);

			// Index all assets
			indexModAssets(modConfig);

			trace('Loaded mod: ${modConfig.name} v${modConfig.version}');
		}
		catch (e)
		{
			trace('Error loading mod at $path: $e');
		}
	}

	static function indexModAssets(mod:ModData)
	{
		function indexFolder(folder:String)
		{
			var path = '${mod.path}/$folder';
			if (!FileSystem.exists(path))
				return;

			for (file in FileSystem.readDirectory(path))
			{
				var filePath = '$path/$file';
				if (FileSystem.isDirectory(filePath))
				{
					indexFolder('$folder/$file');
				}
				else
				{
					var key = '$folder/$file';
					modAssets.set(key, filePath);
				}
			}
		}

		indexFolder("songs");
		indexFolder("images");
		indexFolder("sounds");
		indexFolder("data");
		indexFolder("scripts");
	}

	public static function getAsset(path:String):String
	{
		return modAssets.exists(path) ? modAssets.get(path) : null;
	}

	private static function initializeModScripts()
	{
		for (mod in activeMods)
		{
			var scriptsPath = '${mod.path}/scripts';
			if (FileSystem.exists(scriptsPath))
			{
				loadModScripts(mod, scriptsPath);
			}
		}
	}

	private static function loadModScripts(mod:ModData, path:String)
	{
		for (file in FileSystem.readDirectory(path))
		{
			if (file.endsWith('.hx'))
			{
				var scriptId = '${mod.name}:${file.substr(0, file.length - 3)}';
				var manager = new ScriptManager();
				if (manager.loadScriptFile('$path/$file'))
				{
					modScripts.set(scriptId, manager);
					trace('Loaded mod script: $scriptId');
				}
			}
		}
	}
}

typedef ModData =
{
	var name:String;
	var description:String;
	var version:String;
	var author:String;
	var ?path:String;
	var ?dependencies:Array<String>;
	var ?loadPriority:Int;
}
