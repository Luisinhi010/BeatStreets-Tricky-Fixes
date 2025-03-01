package;

import Song.SwagSong;
import flixel.FlxG;

/**
 * ...
 * @author
 */
typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Int;
}

class Conductor
{
	public static var bpm:Int = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var beatTime:Float = crochet / 1000;
	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000); // is calculated in create(), is safeFrames in milliseconds
	public static var timeScale:Float = Conductor.safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new()
	{
	}

	public static function recalculateTimings()
	{
		Conductor.safeFrames = FlxG.save.data.frames;
		Conductor.safeZoneOffset = Math.floor((Conductor.safeFrames / 60) * 1000);
		Conductor.timeScale = Conductor.safeZoneOffset / 166;
	}

	public static function mapBPMChanges(song:SwagSong):Void
	{
		try
		{
			trace('Conductor: Mapping BPM changes for song');
			trace('Conductor: Initial BPM: ${song.bpm}');

			bpmChangeMap = [];

			if (song?.notes == null)
				return;

			var curBPM:Int = song.bpm;
			var totalSteps:Int = 0;
			var totalPos:Float = 0;

			for (section in song.notes)
			{
				if (section == null)
					continue;

				if (section.changeBPM && section.bpm != curBPM && section.bpm > 0)
				{
					curBPM = section.bpm;
					bpmChangeMap.push({
						stepTime: totalSteps,
						songTime: totalPos,
						bpm: curBPM
					});
				}

				totalSteps += section.lengthInSteps;
				totalPos += ((60 / curBPM) * 1000 / 4) * section.lengthInSteps;
			}

			trace("new BPM map BUDDY " + bpmChangeMap);
			trace('Conductor: BPM map complete. Found ${bpmChangeMap.length} changes');
		}
		catch (e:Dynamic)
		{
			trace('Conductor: Error mapping BPM changes - ${e}');
			bpmChangeMap = [];
		}
	}

	public static function changeBPM(newBpm:Int):Void
	{
		if (newBpm <= 0)
			return;

		var oldBPM = bpm;
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
		beatTime = crochet / 1000;

		trace('Conductor: BPM changed from ${oldBPM} to ${bpm}');
	}
}
