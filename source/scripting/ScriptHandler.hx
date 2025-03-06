package scripting;

import sys.FileSystem;
import flixel.FlxState;

using StringTools;

class ScriptHandler
{
	public static var scripts:Map<String, ScriptManager> = new Map();
	private static var initialized:Bool = false;

	public static function init()
	{
		if (initialized)
			return;
		initialized = true;

		loadGlobalScripts();
	}

	private static function loadGlobalScripts()
	{
		// Verificar em ambos os caminhos: assets/scripts/global e assets/preload/scripts/global
		var paths = ['scripts/global', 'preload/scripts/global'];
		
		for (basePath in paths)
		{
			var fullPath = 'assets/' + basePath;
			if (FileSystem.exists(fullPath))
			{
				for (file in FileSystem.readDirectory(fullPath))
				{
					if (file.endsWith('.hx'))
					{
						var scriptName = file.substr(0, file.length - 3);
						loadGlobalScript(scriptName);
					}
				}
			}
		}
	}

	public static function getActiveScriptCount():Int
	{
		var count = 0;
		for (script in scripts)
			if (script != null)
				count++;
		return count;
	}

	public static function loadClassScript(className:String):ScriptManager
	{
		// Extract only the class name without the package
		var simpleName = className;
		if (className.indexOf('.') != -1)
			simpleName = className.substring(className.lastIndexOf('.') + 1);
		
		var scriptPath = 'class/$simpleName';  // Removed 'scripts/' prefix since it's added later
		trace('Attempting to load class script: $scriptPath');
		
		return loadScriptFromPath(scriptPath, 'class_$simpleName');
	}

	public static function loadGlobalScript(scriptName:String):ScriptManager
	{
		var scriptPath = 'global/$scriptName';  // Removed 'scripts/' prefix since it's added later
		return loadScriptFromPath(scriptPath, 'global_$scriptName');
	}

	private static function loadScriptFromPath(scriptPath:String, id:String):ScriptManager
	{
		// Check for dependency cycles/recursion
		static var loadingScripts:Map<String, Bool> = new Map();
		if (loadingScripts.exists(id))
		{
			trace('Warning: Dependency cycle detected when loading $id');
			return null;
		}
		
		// Check if script is already loaded
		if (scripts.exists(id))
			return scripts.get(id);
		
		loadingScripts.set(id, true);
			
		// Check if file exists - correct the path to check in both locations
		var fullPath = 'scripts/' + scriptPath + '.hx';  // Check in assets/scripts first
		var preloadPath = 'preload/scripts/' + scriptPath + '.hx'; // Also check in assets/preload/scripts
		
		trace('Checking script existence: $fullPath and $preloadPath');
		
		var scriptContent:String = null;
		
		// Try to load from compiled assets/scripts first
		if (sys.FileSystem.exists('assets/$fullPath'))
		{
			scriptContent = sys.io.File.getContent('assets/$fullPath');
			trace('Script found in: assets/$fullPath');
		}
		// Then try assets/preload/scripts
		else if (sys.FileSystem.exists('assets/$preloadPath'))
		{
			scriptContent = sys.io.File.getContent('assets/$preloadPath');
			trace('Script found in: assets/$preloadPath');
		}
		// Then try using Paths
		else if (Paths.exists(fullPath))
		{
			scriptContent = Paths.getText(fullPath);
			trace('Script found via Paths: $fullPath');
		}
		else if (Paths.exists(preloadPath))
		{
			scriptContent = Paths.getText(preloadPath);
			trace('Script found via Paths: $preloadPath');
		}
		
		if (scriptContent == null || scriptContent.trim().length == 0)
		{
			trace('Script empty or not found: $fullPath or $preloadPath');
			loadingScripts.remove(id);
			return null;
		}
		
		// Load and execute script
		var manager = new ScriptManager();
		if (manager.loadScript(scriptContent, fullPath))
		{
			trace('Script loaded successfully: $fullPath');
			
			// Check available functions for debug
			var availableFunctions = [];
			for (name in manager.script.variables.keys())
			{
				var value = manager.script.variables.get(name);
				if (Reflect.isFunction(value))
					availableFunctions.push(name);
			}
			
			if (availableFunctions.length > 0)
				trace('Available functions in script: ' + availableFunctions.join(", "));
			else
				trace('Warning: No functions found in script');
				
			scripts.set(id, manager);
			loadingScripts.remove(id);
			return manager;
		}
		
		trace('Failed to load script: $fullPath');
		loadingScripts.remove(id);
		return null;
	}

	public static function clearScripts()
	{
		for (script in scripts)
			if (script != null)
				script.destroy();
		scripts.clear();
	}
}
