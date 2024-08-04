import openfl.Lib;
import flixel.FlxG;

class KadeEngineData
{
	public static function initSave()
	{
		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		if (FlxG.save.data.accuracyDisplay == null)
			FlxG.save.data.accuracyDisplay = true;

		if (FlxG.save.data.offset == null)
			FlxG.save.data.offset = 0;

		if (FlxG.save.data.fps == null)
			FlxG.save.data.fps = false;

		if (FlxG.save.data.changedHit == null)
		{
			FlxG.save.data.changedHitX = -1;
			FlxG.save.data.changedHitY = -1;
			FlxG.save.data.changedHit = false;
		}

		if (FlxG.save.data.fpsCap == null)
			FlxG.save.data.fpsCap = 120;

		if (FlxG.save.data.fpsCap > 290 || FlxG.save.data.fpsCap < 60)
			FlxG.save.data.fpsCap = 120; // baby proof so you can't hard lock ur copy of kade engine

		if (FlxG.save.data.scrollSpeed == null)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.frames == null)
			FlxG.save.data.frames = 10;

		if (FlxG.save.data.accuracyMod == null)
			FlxG.save.data.accuracyMod = 1;

		if (FlxG.save.data.ghost == null)
			FlxG.save.data.ghost = true;

		if (FlxG.save.data.flashing == null)
			FlxG.save.data.flashing = true;

		if (FlxG.save.data.botplay == null)
			FlxG.save.data.botplay = false;

		if (FlxG.save.data.beatenHard == null)
			FlxG.save.data.beatenHard = false;

		if (FlxG.save.data.beatEx == null)
			FlxG.save.data.beatEx = false;

		if (FlxG.save.data.lowend == null)
			FlxG.save.data.lowend = false;

		if (FlxG.save.data.Warned == null)
			FlxG.save.data.Warned = false;

		Conductor.recalculateTimings();

		KeyBinds.keyCheck();
		PlayerSettings.player1.controls.loadKeyBinds();

		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}
}
