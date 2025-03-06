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
	public static var initialized:Bool = false;

	public static function init()
	{
		if (!FileSystem.exists(modsFolder))
			FileSystem.createDirectory(modsFolder);

		loadMods();
		initializeModScripts();
		Paths.init();
		initialized = true;
	}

	public static function loadMods()
	{
		activeMods = [];
		modAssets.clear();

		if (!FileSystem.exists(modsFolder))
			return;

		// First read modList.txt to load mods in correct order
		var modList:Array<String> = [];
		if (FileSystem.exists('${modsFolder}modList.txt'))
		{
			var modListContent = File.getContent('${modsFolder}modList.txt');
			modList = modListContent.split('\n').map(line -> line.trim());
		}
		
		// First load mods from list in order
		for (modName in modList)
		{
			if (modName.length > 0)
			{
				var modPath = '${modsFolder}${modName}';
				if (FileSystem.exists(modPath) && FileSystem.isDirectory(modPath))
					loadMod(modPath);
			}
		}
		
		// Then load other mods that aren't in the list
		for (modFolder in FileSystem.readDirectory(modsFolder))
		{
			var modPath = '${modsFolder}${modFolder}';
			if (FileSystem.isDirectory(modPath) && !modList.contains(modFolder))
				loadMod(modPath);
		}
		
		// Sort mods by priority
		activeMods.sort((a, b) -> {
			var prioA = a.loadPriority != null ? a.loadPriority : 0;
			var prioB = b.loadPriority != null ? b.loadPriority : 0; // Fixed: was using a.loadPriority
			return prioB - prioA; // Higher priority first
		});
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
			
			if (modConfig.name == null || modConfig.name.length == 0)
			{
				var folderName = path.split("/").pop();
				if (folderName.endsWith("\\"))
					folderName = folderName.substr(0, folderName.length - 1);
				modConfig.name = folderName;
			}
			
			if (modConfig.version == null)
				modConfig.version = "1.0.0";
				
			if (modConfig.description == null)
				modConfig.description = "";
				
			if (modConfig.author == null)
				modConfig.author = "Unknown";
			
			activeMods.push(modConfig);

			// Index all assets
			indexModAssets(modConfig);

			trace('Loaded mod: ${modConfig.name} v${modConfig.version} by ${modConfig.author}');
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
		if (path == null) return null;
		
		// Normalize file path
		var normalizedPath = path.replace("\\", "/");
		
		// First check in assets cache
		if (modAssets.exists(normalizedPath)) 
			return modAssets.get(normalizedPath);

		// Try to find based on mods structure (Paths compatibility)
		for (mod in activeMods)
		{
			var modFilePath = '${mod.path}/${normalizedPath}';
			if (FileSystem.exists(modFilePath) && !FileSystem.isDirectory(modFilePath))
				return modFilePath;
		}
			
		return null;
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
		// Recursive helper function
		function loadScriptsInFolder(folder:String) {
			try {
				for (file in FileSystem.readDirectory(folder)) {
					var fullPath = '$folder/$file';
					
					if (FileSystem.isDirectory(fullPath)) {
						loadScriptsInFolder(fullPath);
					}
					else if (file.endsWith('.hx')) {
						// Create an ID that reflects the folder structure
						var relativePath = fullPath.substr(path.length + 1);
						var scriptId = '${mod.name}:${relativePath.substr(0, relativePath.length - 3)}';
						
						var manager = new ScriptManager();
						if (manager.loadScriptFile(fullPath)) {
							modScripts.set(scriptId, manager);
							trace('Loaded mod script: $scriptId');
						}
					}
				}
			} catch (e) {
				trace('Error reading scripts folder $folder: $e');
			}
		}
		
		loadScriptsInFolder(path);
	}
	
	// Reload mods and update Paths
	public static function reloadMods()
	{
		loadMods();
		initializeModScripts();
		
		// Update Paths system
		Paths.init();
		
		trace('Mods reloaded: ${activeMods.length} mods loaded');
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
