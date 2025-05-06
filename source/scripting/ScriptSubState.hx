package scripting;

import flixel.FlxSubState;
import flixel.FlxG;

/** 
 * Base substate that loads and executes HScript files from substate/ folder
 * Handles:
 * - Script loading/unloading  
 * - Lifecycle events (onCreate, onUpdate, onDestroy)
 */
class ScriptSubState extends MusicBeatSubstate
{
	var scriptName:String;
	var scriptManager:ScriptManager;

	public function new(scriptName:String)
	{
		super();
		this.scriptName = scriptName;
	}

	override function create()
	{
		try
		{
			super.create();

			if (scriptName != null)
			{
				scriptManager = ScriptHandler.loadSubStateScript(scriptName);
				if (scriptManager != null)
				{
					// Add core references
					scriptManager.setVariable("subState", this);
					scriptManager.setVariable("State", FlxG.state);

					callScriptFunction("onCreate");
				}
				else
				{
					trace('Failed to load substate script: $scriptName');
				}
			}
		}
		catch (e)
		{
			trace('Error in substate create: ${e.message}');
			if (ScriptManager.DEBUG)
				trace(e.stack);
		}
	}

	private function callScriptFunction(name:String, ?args:Array<Dynamic>)
	{
		if (scriptManager != null)
		{
			try
			{
				return scriptManager.callFunction(name, args);
			}
			catch (e)
			{
				trace('Error calling script function $name: $e');
			}
		}
		return null;
	}

	override function update(elapsed:Float)
	{
		try
		{
			if (scriptManager != null)
				callScriptFunction("onUpdate", [elapsed]);
			super.update(elapsed);
		}
		catch (e)
		{
			trace('Error in substate update: ${e.message}');
		}
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
