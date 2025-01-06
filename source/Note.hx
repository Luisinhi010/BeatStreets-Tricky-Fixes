package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class Note extends FlxSprite
{
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

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;
	public static inline var X_OFFSET:Float = 50;
	public static inline var Y_OFFSET:Float = 2000;
	public static inline var BURNING_OFFSET:Float = 48;
	public static inline var HALO_OFFSET:Float = 165;
	public var rating:String = "shit";

	public function new(_strumTime:Float, _noteData:Int, type:Dynamic, ?_prevNote:Note, ?sustainNote:Bool = false, ?isPlayer:Bool = false, hard:Bool = false)
	{
		super();

		prevNote = _prevNote != null ? _prevNote : this;
		isSustainNote = sustainNote;

		x += X_OFFSET;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= Y_OFFSET;
		strumTime = Math.max(_strumTime + FlxG.save.data.offset, 0);

		if (_noteData > 7)
		{
			_noteData -= 8;
			type = true;
		}

		burning = type != null && (type == true || type >= 1);

		if (isSustainNote && prevNote.burning)
			burning = true;
		if (isSustainNote && FlxG.save.data.downscroll)
			flipY = true;

		noteData = _noteData % 4;

		var path:String = !hard && !FlxG.save.data.lowend ? 'customnotes/Custom_notes' : 'customnotes/Custom_notes_Expurgation';
		frames = Paths.getSparrowAtlas(path, 'shared');

		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		animation.addByPrefix('purpleholdend', 'pruple end hold');
		animation.addByPrefix('greenholdend', 'green hold end');
		animation.addByPrefix('redholdend', 'red hold end');
		animation.addByPrefix('blueholdend', 'blue hold end');

		animation.addByPrefix('purplehold', 'purple hold piece');
		animation.addByPrefix('greenhold', 'green hold piece');
		animation.addByPrefix('redhold', 'red hold piece');
		animation.addByPrefix('bluehold', 'blue hold piece');

		if (burning)
		{
			if (PlayState.SONG.haloNotes)
			{
				frames = Paths.getSparrowAtlas('fourth/mech/ALL_deathnotes', 'clown');
				animation.addByPrefix('greenScroll', 'Green Arrow');
				animation.addByPrefix('redScroll', 'Red Arrow');
				animation.addByPrefix('blueScroll', 'Blue Arrow');
				animation.addByPrefix('purpleScroll', 'Purple Arrow');
				x -= HALO_OFFSET;
			}
			else
			{
				frames = Paths.getSparrowAtlas('NOTE_fire', 'clown');
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

				x -= BURNING_OFFSET;
			}
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		antialiasing = !FlxG.save.data.lowend;

		if (burning)
			setGraphicSize(Std.int(width * 0.86));

		switch (noteData)
		{
			case 0:
				x += swagWidth * 0;
				animation.play('purpleScroll');
			case 1:
				x += swagWidth * 1;
				animation.play('blueScroll');
			case 2:
				x += swagWidth * 2;
				animation.play('greenScroll');
			case 3:
				x += swagWidth * 3;
				animation.play('redScroll');
		}


		if (isSustainNote && prevNote != null)
		{
			noteScore *= 0.2;
			alpha = 0.6;

			x += width / 2;
			
			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			x -= width / 2;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isSustainNote && prevNote.burning)
			this.kill();

		if (mustPress)
		{
			canBeHit = strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * (burning ? (PlayState.SONG.haloNotes ? 0.2 : 0.3) : 0.5));
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;
			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate && alpha > 0.3)
			alpha = 0.3;
	}
}
