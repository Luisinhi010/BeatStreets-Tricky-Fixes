package scripting;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;

class ScriptState extends MusicBeatState
{
	public var scriptPath:String;
	public var scriptManager:ScriptManager;

	public static var persistentVars:Map<String, Dynamic> = new Map();

	public static function updatePersistentVar(key:String, value:Dynamic):Void
	{
		persistentVars.set(key, value);
	}

	public static function removePersistentVar(key:String):Bool
	{
		return persistentVars.remove(key);
	}

	public static function clearPersistentVars():Void
	{
		persistentVars.clear();
	}

	private var transitionData:Dynamic;

	public function new(scriptPath:String, ?transitionData:Dynamic)
	{
		super();
		this.scriptPath = scriptPath;
		this.transitionData = transitionData;
		scriptManager = new ScriptManager();
	}

	override function create()
	{
		super.create();

		if (scriptPath != null && sys.FileSystem.exists(scriptPath))  // Added existence check
		{
			var script = sys.io.File.getContent(scriptPath);
			scriptManager.loadScript(script, scriptPath);
			scriptManager.setVariable("state", this);
			scriptManager.setVariable("transition", transitionData);

			// Restaurar variáveis persistentes
			for (key => value in persistentVars)
			{
				scriptManager.setVariable(key, value);
			}

			callScriptFunction("onCreate");
		}
		else if (scriptPath != null)
		{
			trace('Error: Script file does not exist: $scriptPath');
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		callScriptFunction("onUpdate", [elapsed]);
	}

	override function destroy()
	{
		callScriptFunction("onDestroy");
		scriptManager.destroy();
		super.destroy();
	}

	private function callScriptFunction(name:String, ?args:Array<Dynamic>)
	{
		if (scriptManager != null)
		{
			return scriptManager.callFunction(name, args);
		}
		return null;
	}

	public static function switchWithData(scriptPath:String, data:Dynamic)
	{
		if (!sys.FileSystem.exists(scriptPath)) {
			trace('Erro: arquivo de script não existe: $scriptPath');
			return;
		}
		
		FlxG.switchState(new ScriptState(scriptPath, data));
	}

	public function persistVariable(name:String)
	{
		var value = scriptManager.get(name);
		if (value != null)
			persistentVars.set(name, value);
	}
}
