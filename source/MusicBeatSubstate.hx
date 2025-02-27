package;

import scripting.ScriptManager;
import scripting.ScriptHandler;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
    public var substateScript:ScriptManager;

    public function new()
    {
        super();
    }

    override function create() {
        substateScript = ScriptHandler.loadClassScript(Type.getClassName(Type.getClass(this)));
        if (substateScript != null) {
            substateScript.set("substate", this);
            substateScript.callFunction("onCreate");
        }

        super.create();
    }

    private var lastBeat:Float = 0;
    private var lastStep:Float = 0;

    private var curStep:Int = 0;
    private var curBeat:Int = 0;
    private var controls(get, never):Controls;

    inline function get_controls():Controls
        return PlayerSettings.player1.controls;

    var halfupdate:Bool = false;
    var curelapsed:Float = 0;

    override function update(elapsed:Float)
    {
        if (substateScript != null)
            substateScript.callFunction("onUpdate", [elapsed]);

        // everyStep();
        halfupdate = !halfupdate;
        if (halfupdate)
            curelapsed += elapsed;
        else
            curelapsed = elapsed;

        var oldStep:Int = curStep;

        updateCurStep();
        curBeat = Math.floor(curStep / 4);

        if (oldStep != curStep && curStep > 0)
            stepHit();

        super.update(elapsed);
    }

    override function destroy() {
        if (substateScript != null) {
            substateScript.callFunction("onDestroy");
            substateScript.destroy();
            substateScript = null;
        }

        super.destroy();
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
            if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
                lastChange = Conductor.bpmChangeMap[i];
        }

        curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
    }

    public function stepHit():Void
    {
        if (curStep % 4 == 0)
            beatHit();
    }

    public function beatHit():Void
    {
        // do literally nothing dumbass
    }
}
