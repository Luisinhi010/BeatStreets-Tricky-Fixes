package;

import Song.SwagSong;
import flixel.FlxG;

/**
 * Handles timing and BPM-related functionality.
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

	/**
	 * Recalculates timing values based on current settings
	 */
	public static function recalculateTimings()
	{
		// Adjust safeZoneOffset based on frameRate
		var frameRate:Int = FlxG.save.data.fpsCap;
		if (frameRate <= 0)
			frameRate = lime.app.Application.current.window.displayMode.refreshRate;
		if (frameRate < 60)
			frameRate = 60;

		safeFrames = FlxG.save.data.frames;
		safeZoneOffset = Math.floor((safeFrames / frameRate) * 1000);
		timeScale = safeZoneOffset / 166;

		// Ensure timeScale is always within reasonable limits
		if (timeScale < 0.1)
			timeScale = 0.1;
		else if (timeScale > 2)
			timeScale = 2;

		trace('Conductor: Timings recalculated - safeFrames: $safeFrames, safeZoneOffset: $safeZoneOffset, frameRate: $frameRate, timeScale: $timeScale');
	}

	/**
	 * Maps all BPM changes throughout the song
	 * @param song The song to map BPM changes for
	 */
	public static function mapBPMChanges(song:SwagSong):Void
	{
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

				trace('BPM Change: $curBPM at step $totalSteps (song time: $totalPos)');
			}

			var sectionLength = section.lengthInSteps;
			if (sectionLength == 0)
				sectionLength = 16; // Default length

			totalSteps += sectionLength;
			totalPos += ((60 / curBPM) * 1000 / 4) * sectionLength;
		}

		trace('BPM map complete. Found ${bpmChangeMap.length} changes');
	}

	/**
	 * Gets the BPM at a specific time in the song
	 * @param time Time in milliseconds
	 * @return Current BPM at specified time
	 */
	public static function getBPMFromSeconds(time:Float):Float
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm
		};

		// Optimization: Binary search for BPM changes
		if (bpmChangeMap.length > 0)
		{
			var low:Int = 0;
			var high:Int = bpmChangeMap.length - 1;

			while (low <= high)
			{
				var mid:Int = Math.floor((low + high) / 2);

				if (bpmChangeMap[mid].songTime <= time && (mid == bpmChangeMap.length - 1 || bpmChangeMap[mid + 1].songTime > time))
				{
					lastChange = bpmChangeMap[mid];
					break;
				}
				else if (bpmChangeMap[mid].songTime > time)
				{
					high = mid - 1;
				}
				else
				{
					low = mid + 1;
				}
			}
		}

		return lastChange.bpm;
	}

	/**
	 * Gets the current step at a specific time in the song
	 * @param time Time in milliseconds
	 * @return Step number
	 */
	public static function getStep(time:Float):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm
		};

		for (i in 0...bpmChangeMap.length)
		{
			if (time >= bpmChangeMap[i].songTime)
				lastChange = bpmChangeMap[i];
		}

		var stepTime:Float = lastChange.stepTime;
		var songTime:Float = lastChange.songTime;
		var stepCrochet:Float = ((60 / lastChange.bpm) * 1000) / 4;

		return Math.floor(stepTime + (time - songTime) / stepCrochet);
	}

	/**
	 * Gets the current beat at a specific time in the song
	 * @param time Time in milliseconds
	 * @return Beat number as a float (can be fractional)
	 */
	public static function getBeat(time:Float):Float
	{
		return getStep(time) / 4;
	}

	/**
	 * Changes the current BPM and recalculates timing values
	 * @param newBpm New BPM value
	 */
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
