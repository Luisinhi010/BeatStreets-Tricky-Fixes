package scripting;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;

/**
 * Base state class that supports script loading and execution
 * 
 * Features:
 * - Automatic script loading for states
 * - Event dispatching
 * - Script lifecycle management
 */
class ScriptState extends MusicBeatState
{
	public var scriptName:String;
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

	public function new(scriptName:String, ?transitionData:Dynamic)
	{
		super();
		this.scriptName = scriptName;
		this.transitionData = transitionData;
	}

	override function create()
	{
		try
		{
			super.create();

			if (scriptName != null)
			{
				scriptManager = ScriptHandler.loadStateScript(scriptName);
				if (scriptManager != null)
				{
					// Add core references
					scriptManager.setVariable("state", this);
					scriptManager.setVariable("transition", transitionData);

					// Add persistent variables
					for (key => value in persistentVars)
					{
						if (value != null)
						{
							scriptManager.setVariable(key, value);
						}
					}

					callScriptFunction("onCreate");
				}
				else
				{
					trace('Failed to load state script: $scriptName');
				}
			}
		}
		catch (e)
		{
			trace('Error in state create: ${e.message}');
			if (ScriptManager.DEBUG)
				trace(e.stack);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		callScriptFunction("onUpdate", [elapsed]);
	}

	override function destroy()
	{
		try
		{
			if (scriptManager != null)
			{
				callScriptFunction("onDestroy");
				scriptManager.destroy();
				scriptManager = null;
			}
			super.destroy();
		}
		catch (e)
		{
			trace('Error in state destroy: ${e.message}');
		}
	}

	private function callScriptFunction(name:String, ?args:Array<Dynamic>)
	{
		if (scriptManager != null)
		{
			return scriptManager.callFunction(name, args);
		}
		return null;
	}

	public static function switchWithData(scriptName:String, data:Dynamic)
	{
		FlxG.switchState(new ScriptState(scriptName, data));
	}

	public function persistVariable(name:String)
	{
		var value = scriptManager.get(name);
		if (value != null)
			persistentVars.set(name, value);
	}
}
