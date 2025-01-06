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

class Song
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

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		try
		{
			var rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase()));
			return parseAndAdjustNoteData(rawJson);
		}
		catch (e:Dynamic)
		{
			trace('Error parsing JSON: $e');
			return null;
		}
	}

	public static function parseAndAdjustNoteData(rawJson:String):SwagSong
	{
		var swagSong:SwagSong = cast Json.parse(rawJson).song;
		for (i in swagSong.notes)
		{
			for (j in i.sectionNotes)
			{
				if (j[1] > 7)
					{
						j[1] -= 8;
						j[3] = true;
					}
					if (j[3] == null)
						j[3] = false;
					if (j[3] is String && j[3].toLowerCase() == 'null') // as far i know this only fix chart ported from codename
						j[3] = false;
					if (j[3] is String && j[3].toLowerCase() == 'hurt note') // support to psych engine
						j[3] = true;
					if (j[3] is Int && j[3] >= 1) // support to mods that use int as types of notes
						j[3] = true;
			}
		}
		if (swagSong.stage == null)
			swagSong.stage = 'nevada';
		if (swagSong.gfVersion == null)
			swagSong.gfVersion = 'gf';
		if (swagSong.haloNotes == null)
			swagSong.haloNotes = false;
		return swagSong;
	}
}
