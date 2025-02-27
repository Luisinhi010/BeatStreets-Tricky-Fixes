package scripting;

import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.FlxG;
import effects.CameraEffects;

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
		scriptManager.setVariable("state", state);

		loadSongScript();
	}

	private function loadSongScript()
	{
		var scriptPath = 'assets/preload/data/songs/${songName.toLowerCase()}/script.hx';
		if (sys.FileSystem.exists(scriptPath))
		{
			var script = sys.io.File.getContent(scriptPath);
			scriptManager.loadScript(script, scriptPath);

			// Chamar callbacks se existirem
			if (scriptManager.script.variables.exists("onSongStart"))
				scriptManager.callFunction("onSongStart", [state]);
		}
	}

	private function getCameraByName(name:String):FlxCamera
	{
		return switch (name.toLowerCase())
		{
			case "game": state.camGame;
			case "hud": state.camHUD;
			case "effect": state.camEffect;
			case "other": state.camOther;
			default: null;
		}
	}

	public function update(elapsed:Float)
	{
		if (scriptManager != null && scriptManager.script.variables.exists("onUpdate"))
			scriptManager.callFunction("onUpdate", [elapsed]);
	}

	public function onStep()
	{
		if (scriptManager != null && scriptManager.script.variables.exists("onStep"))
			scriptManager.callFunction("onStep", [state.curStep]);
	}

	public function onBeat()
	{
		if (scriptManager != null && scriptManager.script.variables.exists("onBeat"))
			scriptManager.callFunction("onBeat", [state.curBeat]);
	}

	public function destroy()
	{
		if (scriptManager != null)
		{
			if (scriptManager.script.variables.exists("onDestroy"))
				scriptManager.callFunction("onDestroy", []);
			scriptManager.destroy();
			scriptManager = null;
		}
	}
}
