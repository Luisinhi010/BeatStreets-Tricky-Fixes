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
		var globalScriptsPath = 'assets/preload/data/scripts/global';
		if (FileSystem.exists(globalScriptsPath))
			for (file in FileSystem.readDirectory(globalScriptsPath))
				if (file.endsWith('.hx'))
					loadGeneralScript(file.substr(0, file.length - 3));
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
		var path = 'assets/preload/data/scripts/class/$className.hx';
		return loadScript(path, 'class_$className');
	}

	public static function loadGeneralScript(scriptName:String):ScriptManager
	{
		var path = 'assets/preload/data/scripts/general/$scriptName.hx';
		return loadScript(path, 'general_$scriptName');
	}

	public static function loadSongScript(songName:String):ScriptManager
	{
		var path = 'assets/preload/data/songs/${songName.toLowerCase()}/script.hx';
		return loadScript(path, 'song_$songName');
	}

	private static function loadScript(path:String, id:String):ScriptManager
	{
		if (scripts.exists(id))
			return scripts.get(id);

		if (!FileSystem.exists(path))
			return null;

		var manager = new ScriptManager();
		if (manager.loadScriptFile(path))
		{
			scripts.set(id, manager);
			return manager;
		}
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
