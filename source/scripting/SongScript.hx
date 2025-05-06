package scripting;

import flixel.FlxG;
import effects.CameraEffects;

/**
 * Handles song-specific scripts and their execution
 * 
 * Features:
 * - Song script loading
 * - Song-specific events
 * - Integration with PlayState
 */
class SongScript
{
	public var state:PlayState;
	public var scriptManager:ScriptManager;
	public var songName:String;

	public function new(state:PlayState, songName:String)
	{
		this.state = state;
		this.songName = songName;
		init();
	}

	private function init()
	{
		scriptManager = new ScriptManager();
		scriptManager.setVariable("song", this);
		scriptManager.setVariable("State", state);
		loadSongScript();
	}

	private function loadSongScript()
	{
		trace('Trying to load song script for ${songName}...');
		var scriptData = Paths.getSongScript(songName);

		if (scriptData != null && scriptData.content != null)
		{
			var success = scriptManager.loadScript(scriptData.content, scriptData.path);

			if (success)
			{
				trace('Successfully loaded song script');
				setupVariables();
				callEvent("onSongStart", [state]);
			}
		}
		else
		{
			var path = 'assets/preload/data/${songName.toLowerCase()}/script.hx';
			if (sys.FileSystem.exists(path))
			{
				var success = scriptManager.loadScript(sys.io.File.getContent(path), path);
				if (success)
				{
					trace('Loaded legacy song script');
					setupVariables();
					callEvent("onSongStart", [state]);
				}
			}
			else
			{
				trace('No script found for song ${songName}');
			}
		}
	}

	private function setupVariables()
	{
		scriptManager.setVariable("State", state);
		scriptManager.setVariable("song", this);
	}

	private function callEvent(name:String, ?args:Array<Dynamic>):Dynamic
	{
		return EventDispatcher.dispatch(scriptManager, name, args);
	}

	public function destroy()
	{
		if (scriptManager != null)
		{
			callEvent("onDestroy");
			scriptManager.destroy();
			scriptManager = null;
		}
	}
}
