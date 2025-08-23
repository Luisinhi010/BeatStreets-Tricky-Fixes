package;

import Section.SwagSection;
import haxe.Json;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var haloNotes:Null<Bool>;
}

class Song // Utility class for loading and parsing SwagSong data
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var stage:String = 'nevada';
	public var haloNotes:Bool = false;

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, folder:String):SwagSong
	{
		try
		{
			var rawJson = Assets.getText(Paths.json(folder + '/' + jsonInput)).trim();
			if (rawJson == null)
			{
				trace('Song JSON not found: ${jsonInput}');
				return null;
			}

			return parseAndAdjustNoteData(rawJson);
		}
		catch (e:Dynamic)
		{
			trace('Error loading song JSON: ${e}');
			return null;
		}
	}

	public static function parseAndAdjustNoteData(rawJson:String):SwagSong
	{
		var swagSong:SwagSong = cast Json.parse(rawJson).song;

		// Set default values for optional fields
		if (swagSong.stage == null)
			swagSong.stage = 'nevada';
		if (swagSong.gfVersion == null)
			swagSong.gfVersion = 'gf';
		if (swagSong.haloNotes == null)
			swagSong.haloNotes = false;

		for (section in swagSong.notes)
		{
			for (noteData in section.sectionNotes)
			{
				// In some chart formats, the 4th value (for special notes like "burning")
				// is encoded into the second value (noteData). This adjusts for that.
				if (noteData[1] > 7)
				{
					noteData[1] -= 8;
					noteData[3] = true;
				}
				else if (noteData[3] == null)
					noteData[3] = false;
				else if (noteData[3] is String)
					noteData[3] = noteData[3].toLowerCase() == 'true';
				else if (noteData[3] is Int)
					noteData[3] = noteData[3] >= 1;
			}
		}
		return swagSong;
	}
}
