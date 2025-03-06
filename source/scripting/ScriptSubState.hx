package scripting;

import flixel.FlxSubState;

class ScriptSubState extends MusicBeatSubstate
{
	var scriptPath:String;
	var scriptManager:ScriptManager;

	public function new(scriptPath:String)
	{
		super();
		this.scriptPath = scriptPath;
	}

	override function create()
	{
		scriptManager = new ScriptManager();
		
		if (sys.FileSystem.exists(scriptPath)) {
			if (scriptManager.loadScriptFile(scriptPath))
			{
				scriptManager.set("subState", this);
				scriptManager.callFunction("onCreate");
			}
			else {
				trace('Erro ao carregar o script: $scriptPath');
			}
		}
		else {
			trace('Arquivo de script não encontrado: $scriptPath');
		}
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (scriptManager != null)
			scriptManager.callFunction("onUpdate", [elapsed]);
		super.update(elapsed);
	}

	override function destroy()
	{
		if (scriptManager != null)
		{
			scriptManager.callFunction("onDestroy");
			scriptManager.destroy();
		}
		super.destroy();
	}
}
