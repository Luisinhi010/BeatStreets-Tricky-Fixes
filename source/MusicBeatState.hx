package;

import scripting.*;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.Lib;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	public var controls(get, never):Controls;

	public var stateScript:ScriptManager;
	public var enableScript:Bool = true;

	public inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function dispatchScriptEvent(event:String, ?args:Array<Dynamic>)
		if (enableScript)
			EventDispatcher.dispatchToAll([stateScript], event, args);

	override function create()
	{
		Main.setFPSCap(FlxG.save.data.fpsCap);

		// if (transIn != null)
		//	trace('reg ' + transIn.region);

		// Load class-specific script
		if (enableScript)
		{
			trace('Loading class-specific script for: ' + Type.getClassName(Type.getClass(this)));
			stateScript = ScriptHandler.loadClassScript(Type.getClassName(Type.getClass(this)));
			if (stateScript != null)
			{
				trace('Script loaded successfully');
				stateScript.set("State", this);
			}
		}
		dispatchScriptEvent("onCreate");

		super.create();
	}

	var halfupdate:Bool = false;
	var curelapsed:Float = 0;

	override function update(elapsed:Float)
	{
		// everyStep();
		halfupdate = !halfupdate;
		if (halfupdate)
			curelapsed += elapsed;
		else
			curelapsed = elapsed;

		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		if (Main.getFPSCap != FlxG.save.data.fpsCap && FlxG.save.data.fpsCap <= 290)
			Main.setFPSCap(FlxG.save.data.fpsCap);

		if (FlxG.keys.justPressed.F5)
			FlxG.resetState();

		dispatchScriptEvent("onUpdate", [elapsed]);

		super.update(elapsed);
	}

	override function destroy()
	{
		trace("Destroying " + Type.getClassName(Type.getClass(this)) + ".hx");

		if (stateScript != null)
		{
			dispatchScriptEvent("onDestroy");
			stateScript.destroy();
			stateScript = null;
		}

		ScriptHandler.clearScripts();

		#if cpp
		cpp.vm.Gc.run(true);
		#end

		super.destroy();
	}

	private function updateBeat():Void
	{
		lastBeat = curStep;
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		dispatchScriptEvent("onStepHit", [curStep]);

		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		dispatchScriptEvent("onBeatHit", [curBeat]); // BOB, DO SOMETHING!
	}
}
