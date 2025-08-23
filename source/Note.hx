package;

import lime.utils.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import ConfigManager;

using StringTools;

class Note extends CustomSprite
{
	public static var swagWidth:Float = 0;

	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var burning:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var rating:String = "shit";
	public var customData:Map<String, Dynamic> = new Map();
	public var ignoreNote:Bool = false; // Notes that shouldn't count as misses
	public var hitWindow:Float = 0; // Specific hit window timing for this note

	/**
	 * Creates a new note
	 * @param _strumTime When the note should be hit
	 * @param _noteData Which column/direction (0-3)
	 * @param type Note type (burning, etc)
	 * @param _prevNote Previous note in hold chain
	 * @param sustainNote If this is a sustain note
	 * @param isPlayer If this note is for the player
	 * @param hard Use hard note graphics
	 */
	public function new(_strumTime:Float, _noteData:Int, type:Dynamic, ?_prevNote:Note, ?sustainNote:Bool = false, ?isPlayer:Bool = false, hard:Bool = false)
	{
		super();
		strumTime = Math.max(_strumTime + FlxG.save.data.offset, 0);
		noteData = _noteData % 4;
		mustPress = isPlayer;
		prevNote = _prevNote != null ? _prevNote : this;
		isSustainNote = sustainNote;

		if (swagWidth == 0)
			swagWidth = ConfigManager.getValue(ConfigManager.noteConfig, "dimensions.width",
				160) * ConfigManager.getValue(ConfigManager.noteConfig, "dimensions.scale", 0.7);

		x += ConfigManager.getValue(ConfigManager.noteConfig, "offsets.x", 50);
		y -= ConfigManager.getValue(ConfigManager.noteConfig, "offsets.y", 2000);

		// Process note type
		if (_noteData > 7)
		{
			_noteData -= 8;
			burning = true;
		}
		else
		{
			burning = type != null && (type == true || type >= 1);
		}

		burning = burning || (isSustainNote && prevNote.burning);

		loadNoteGraphics(hard);
	}

	/**
	 * Loads the appropriate graphics for this note type
	 * @param hard Whether to use hard note graphics
	 */
	private function loadNoteGraphics(hard:Bool):Void
	{
		if (burning)
			loadBurningNoteAssets();
		else
		{
			var notePath:String = (!hard && !FlxG.save.data.lowend) ? ConfigManager.getValue(ConfigManager.noteConfig, "paths.defaut.normal",
				"customnotes/Custom_notes") : ConfigManager.getValue(ConfigManager.noteConfig, "paths.defaut.hard", "customnotes/Custom_notes_Expurgation");

			frames = Paths.getSparrowAtlas(notePath, 'shared');

			var animationPrefixes = ['purple', 'blue', 'green', 'red'];
			for (prefix in animationPrefixes)
			{
				animation.addByPrefix('${prefix}Scroll', '${prefix}0');
				animation.addByPrefix('${prefix}holdend', '${prefix} hold end');
				animation.addByPrefix('${prefix}hold', '${prefix} hold piece');
			}
		}

		var scale:Float = ConfigManager.getValue(ConfigManager.noteConfig, "dimensions.scale", 0.7);
		setGraphicSize(Std.int(width * scale));
		updateHitbox();
		antialiasing = !FlxG.save.data.lowend;

		if (burning)
		{
			scale = ConfigManager.getValue(ConfigManager.noteConfig, "dimensions.burningScale", 0.86);
			setGraphicSize(Std.int(width * scale));
		}

		var scrollAnims:Array<String> = ['purpleScroll', 'blueScroll', 'greenScroll', 'redScroll'];
		animation.play(scrollAnims[noteData]);
		x += swagWidth * noteData;

		if (isSustainNote && prevNote != null)
			handleSustainNote();
	}

	function loadBurningNoteAssets():Void
	{
		var haloNotes = PlayState.SONG.haloNotes;
		var path = haloNotes ? ConfigManager.getValue(ConfigManager.noteConfig, "paths.burning.halo",
			"fourth/mech/ALL_deathnotes") : ConfigManager.getValue(ConfigManager.noteConfig, "paths.burning.normal", "NOTE_fire");

		frames = Paths.getSparrowAtlas(path, 'clown');

		if (haloNotes)
		{
			var arrowPrefixes = ['Green', 'Blue', 'Purple', 'Red'];
			for (prefix in arrowPrefixes)
			{
				animation.addByPrefix('${StringTools.replace(prefix, "Red", "red").replace("Blue", "blue").replace("Green", "green").replace("Purple", "purple")}Scroll',
					'${prefix} Arrow');
			}
			x -= ConfigManager.getValue(ConfigManager.noteConfig, "offsets.halo", 165);
		}
		else
		{
			var firePrefixes = ['blue', 'green', 'red', 'purple'];
			if (!FlxG.save.data.downscroll)
			{
				animation.addByPrefix('blueScroll', 'blue fire');
				animation.addByPrefix('greenScroll', 'green fire');
			}
			else
			{
				animation.addByPrefix('greenScroll', 'blue fire');
				animation.addByPrefix('blueScroll', 'green fire');
			}
			animation.addByPrefix('redScroll', 'red fire');
			animation.addByPrefix('purpleScroll', 'purple fire');
			flipY = FlxG.save.data.downscroll;
			x -= ConfigManager.getValue(ConfigManager.noteConfig, "offsets.burning", 48);
		}
	}

	function handleSustainNote():Void
	{
		alpha = 0.6;

		x += width / 2;
		var holdEndAnims = ['purpleholdend', 'blueholdend', 'greenholdend', 'redholdend'];
		animation.play(holdEndAnims[noteData]);

		updateHitbox();

		x -= width / 2;

		if (prevNote.isSustainNote)
		{
			var holdAnims = ['purplehold', 'bluehold', 'greenhold', 'redhold'];
			prevNote.animation.play(holdAnims[prevNote.noteData]);
			prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
			prevNote.updateHitbox();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
			checkCanBeHit();
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && alpha > 0.3)
		{
			alpha = 0.3;

			if (burning && !PlayState.SONG.haloNotes)
				alpha = 0.2;
		}
	}

	function checkCanBeHit():Void
	{
		// Cache variables for better performance
		var currentTime:Float = Conductor.songPosition;
		var noteTime:Float = strumTime;

		if (burning)
		{
			if (PlayState.SONG != null && PlayState.SONG.haloNotes)
				hitWindow = Conductor.safeZoneOffset * ConfigManager.getValue(ConfigManager.noteConfig, "timing.safeZoneOffset.halo", 0.2);
			else
				hitWindow = Conductor.safeZoneOffset * ConfigManager.getValue(ConfigManager.noteConfig, "timing.safeZoneOffset.burning", 0.3);
		}
		else
		{
			hitWindow = Conductor.safeZoneOffset * ConfigManager.getValue(ConfigManager.noteConfig, "timing.safeZoneOffset.normal", 0.5);
		}

		if (hitWindow <= 0)
			hitWindow = Conductor.safeZoneOffset * 0.5;

		var earliestHitWindow:Float = noteTime - Conductor.safeZoneOffset;
		var latestHitWindow:Float = noteTime + hitWindow;

		canBeHit = currentTime >= earliestHitWindow && currentTime <= latestHitWindow;

		if (currentTime > latestHitWindow && !wasGoodHit)
			tooLate = true;

		if (isSustainNote && prevNote != null && prevNote != this)
		{
			if (prevNote.wasGoodHit)
			{
				var sustainStart:Float = prevNote.strumTime;
				canBeHit = currentTime >= sustainStart && currentTime <= latestHitWindow;
			}

			if (prevNote.tooLate && !prevNote.wasGoodHit)
			{
				tooLate = true;
				canBeHit = false;
			}
		}
	}

	override function destroy()
	{
		if (customData != null)
		{
			customData.clear();
			customData = null;
		}
		prevNote = null;

		super.destroy();
	}
}
