package scripting;

import sys.FileSystem;

using StringTools;

/**
 * Manages script loading and execution from both mods and base game.
 * Scripts are loaded from:
 * - assets/scripts/
 *   ├── state/        # State scripts
 *   ├── substate/     # SubState scripts
 *   ├── class/        # Class scripts 
 *   └── global/       # Global utility scripts
 * 
 * - mods/[MOD_NAME]/scripts/ (Same structure as above)
 */
class ScriptHandler
{
	public static var scripts:Map<String, ScriptManager> = new Map();
	private static var initialized:Bool = false;
	public static var loadingScripts:Map<String, Bool> = new Map();

	public static function init()
	{
		if (initialized)
			return;
		initialized = true;

		loadGlobalScripts();
	}

	/**
	 * Gets script path checking mods first, then base game
	 * @param scriptPath Relative path to script
	 * @return Full path to script or null if not found
	 */
	private static function getScriptPath(scriptPath:String):String
	{
		if (scriptPath == null)
			return null;

		var paths = [
			'scripts/$scriptPath.hx',
			'data/scripts/$scriptPath.hx' // Legacy support
		];

		for (path in paths)
		{
			// Tente encontrar em mods primeiro
			var modPath = Paths.getModPath(path);
			if (modPath != null && FileSystem.exists(modPath))
				return modPath;

			// Então procura nos assets
			if (Paths.exists(path))
				return path;
		}

		trace('Script not found: $scriptPath');
		return null;
	}

	private static function getScriptContent(scriptPath:String):String
	{
		var path = getScriptPath(scriptPath);
		if (path != null)
		{
			if (path.startsWith(Paths.MODS_FOLDER))
			{
				return sys.io.File.getContent(path);
			}
			else
			{
				return Paths.getText(path);
			}
		}
		return null;
	}

	private static function loadScriptFromPath(scriptPath:String, id:String):ScriptManager
	{
		// Check for nulls first
		if (scriptPath == null || id == null)
			return null;

		// Avoid loading twice
		if (loadingScripts.exists(id))
		{
			trace('Warning: Dependency cycle detected when loading $id');
			loadingScripts.remove(id);
			return null;
		}

		// Return cached script if exists
		if (scripts.exists(id))
			return scripts.get(id);

		loadingScripts.set(id, true);

		// Load and validate script content
		var scriptContent = getScriptContent(scriptPath);
		if (scriptContent == null || scriptContent.trim().length == 0)
		{
			trace('Script empty or not found: $scriptPath');
			loadingScripts.remove(id);
			return null;
		}

		// Create and initialize script manager
		var manager = new ScriptManager();
		try
		{
			if (manager.loadScript(scriptContent, scriptPath))
			{
				scripts.set(id, manager);
				loadingScripts.remove(id);
				return manager;
			}
		}
		catch (e)
		{
			trace('Error loading script $scriptPath: $e');
		}

		loadingScripts.remove(id);
		return null;
	}

	public static function loadStateScript(stateName:String):ScriptManager
	{
		if (stateName == null)
			return null;

		return loadScriptFromPath('state/$stateName', 'state_$stateName');
	}

	public static function loadSubStateScript(subStateName:String):ScriptManager
	{
		return loadScriptFromPath('substate/$subStateName', 'substate_$subStateName');
	}

	public static function loadClassScript(className:String):ScriptManager
	{
		return loadScriptFromPath('class/$className', 'class_$className');
	}

	public static function loadGlobalScript(scriptName:String):ScriptManager
	{
		return loadScriptFromPath('global/$scriptName', 'global_$scriptName');
	}

	private static function loadGlobalScripts()
	{
		var globalScripts = Paths.listFiles('scripts/global', (file) -> file.endsWith('.hx'));
		for (file in globalScripts)
		{
			var scriptName = file.substr(0, file.length - 3);
			loadGlobalScript(scriptName);
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

	public static function clearScripts()
	{
		trace('Starting script cleanup...');
		var currentScripts = new Map<String, ScriptManager>();

		// Create safe copy of scripts map
		for (id => script in scripts)
			currentScripts.set(id, script);

		// Clear original map first
		scripts.clear();

		// Destroy scripts from copy
		for (id => script in currentScripts)
		{
			if (script != null)
			{
				trace('Destroying script: $id');
				try
				{
					script.destroy();
					script = null;
				}
				catch (e:Dynamic)
				{
					trace('Error destroying script $id: $e');
				}
			}
		}

		// Ensure all references are cleared
		currentScripts.clear();
		currentScripts = null;

		clearLoadingScripts();

		// Force garbage collection
		#if cpp
		cpp.vm.Gc.run(true);
		#end
	}

	public static function clearLoadingScripts()
	{
		var count = Lambda.count(loadingScripts);
		trace('Clearing ${count} loading scripts');
		loadingScripts.clear();

		#if cpp
		cpp.vm.Gc.run(true);
		#end
	}

	public static function reloadScript(id:String):ScriptManager
	{
		if (scripts.exists(id))
		{
			var script = scripts.get(id);
			if (script != null)
			{
				trace('Recarregando script: $id');
				try
				{
					script.destroy();
				}
				catch (e:Dynamic)
				{
					trace('Erro ao destruir script antigo: $e');
				}
				scripts.remove(id);
			}
		}

		// Força coleta de lixo antes de recarregar
		#if cpp
		cpp.vm.Gc.run(true);
		#end

		return loadScriptFromPath(id.substr(id.indexOf('_') + 1), id);
	}
}
