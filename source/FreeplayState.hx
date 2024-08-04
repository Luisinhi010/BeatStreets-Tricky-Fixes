package;

import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionableState;
import AlphabetTricky.TrickyAlphaCharacter;
import flixel.sound.FlxSound;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

using StringTools;

class FreeplayState extends MusicBeatState
{
	public var songs:Array<TrickyButton> = [];

	var selectedIndex = 0;
	var selectedSmth = false;

	public var diff:Int = 0;
	public var curdiff:Int = 0;
	public var diffAndScore:FlxText;

	var debug:Bool = false;

	var songFour:TrickyButton;

	public var diffText:AlphabetTricky;

	public var lastInput:Bool = true;

	public var colorSwap:ColorSwap = null;
	public final upsideOffset:Float = 120 / 360;

	override function create()
	{
		trace(diff);

		#if debug
		debug = true;
		#end
		colorSwap = new ColorSwap();
		FlxG.camera.filters = [new ShaderFilter(colorSwap.shader)];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		songs.push(new TrickyButton(80, 120, 'menu/freeplay/Improbable Outset Button', 'menu/freeplay/Improbable Outset Confirm', selectSong,
			'improbable-outset', -30));
		songs.push(new TrickyButton(80, 240, 'menu/freeplay/Madness Button', 'menu/freeplay/Madness Confirm', selectSong, 'madness', -30));
		songs.push(new TrickyButton(80, 360, 'menu/freeplay/Hellclown Button', 'menu/freeplay/Hellclown Confirm', selectSong, 'hellclown', -30));
		songFour = new TrickyButton(300, 420, 'menu/freeplay/Expurgation Button', 'menu/freeplay/Expurgation Confirm', selectSong, 'expurgation', 0, 15);

		songFour.spriteOne = new FlxSprite(songFour.trueX + songFour.tweenX,
			songFour.trueY + songFour.tweenY).loadGraphic(Paths.image('menu/freeplay/Expurgation Button', 'clown'), true, 800, 200);
		songFour.spriteTwo = new FlxSprite(songFour.trueX + songFour.tweenX,
			songFour.trueY + songFour.tweenY).loadGraphic(Paths.image('menu/freeplay/Expurgation Confirm', 'clown'), true, 800, 200);
		songFour.spriteTwo.alpha = 0;
		songFour.spriteOne.animation.add("static", [0, 1, 2, 3], 12, true);
		songFour.spriteTwo.animation.add("static", [0, 1, 2, 3], 12, true);
		songFour.spriteOne.animation.play("static");
		songFour.spriteTwo.animation.play("static");

		songFour.spriteOne.screenCenter(X);
		songFour.trueX = songFour.spriteOne.x;

		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.y += 40;
		add(bg);
		var hedge:FlxSprite = new FlxSprite(-810, -335).loadGraphic(Paths.image('menu/freeplay/hedge', 'clown'));
		hedge.setGraphicSize(Std.int(hedge.width * 0.65));
		add(hedge);
		var shade:FlxSprite = new FlxSprite(-205, -100).loadGraphic(Paths.image('menu/freeplay/Shadescreen', 'clown'));
		shade.setGraphicSize(Std.int(shade.width * 0.65));
		add(shade);
		var bars:FlxSprite = new FlxSprite(-225, -395).loadGraphic(Paths.image('menu/freeplay/theBox', 'clown'));
		bars.setGraphicSize(Std.int(bars.width * 0.65));
		add(bars);

		if (FlxG.save.data.beatenHard || debug)
			songs.push(songFour);
		else
		{
			var locked:FlxSprite = new FlxSprite(songFour.trueX,
				songFour.trueY).loadGraphic(Paths.image('menu/freeplay/Expurgation Locked', 'clown'), true, 900, 200);
			locked.animation.add("static", [0, 1, 2, 3], 12, true);
			locked.animation.play("static");
			locked.screenCenter(X);
			add(locked);
		}

		for (i in songs)
		{
			// just general compensation since pasc made this on 1920x1080 and we're on 1280x720
			i.spriteOne.setGraphicSize(Std.int(i.spriteOne.width * 0.7));
			i.spriteTwo.setGraphicSize(Std.int(i.spriteTwo.width * 0.7));
			add(i);
			add(i.spriteOne);
			add(i.spriteTwo);
		}

		var score = Highscore.getScore(songs[selectedIndex].pognt, diff);

		diffAndScore = new FlxText(125, 600, 0, diffGet() + " - " + score);
		diffAndScore.setFormat("tahoma-bold.ttf", 42, FlxColor.CYAN);

		add(diffAndScore);

		var menuShade:FlxSprite = new FlxSprite(-1350, -1190).loadGraphic(Paths.image("menu/freeplay/Menu Shade", 'clown'));
		menuShade.setGraphicSize(Std.int(menuShade.width * 0.7));
		add(menuShade);

		songs[0].highlight();
		FlxG.mouse.visible = true;
	}

	function diffGet()
	{
		if (songs[selectedIndex].pognt == 'expurgation')
			return "HARDER THAN EXPECTED";
		switch (diff)
		{
			case 0:
				return "HARD";
			case 1:
				return "OLD";
			case 2:
				return "UPSIDE";
		}
		return "HARD";
	}

	function selectSong()
	{
		var diffToUse:Int = diff;

		FlxG.sound.music.fadeOut();//.onComplete = MainMenuState.theme.stop;

		PlayState.storyDifficulty = diff;

		var poop:String = Highscore.formatSong(songs[selectedIndex].pognt.toLowerCase(), diffToUse);

		PlayState.SONG = Song.loadFromJson(poop, songs[selectedIndex].pognt.toLowerCase());
		PlayState.isStoryMode = false;

		LoadingState.loadAndSwitchState(new PlayState());
		FlxG.mouse.visible = false;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		var score = Highscore.getScore(songs[selectedIndex].pognt, diff); // we only have one difficulty
		diffAndScore.text = diffGet() + " - " + score;

		if (!selectedSmth)
		{
			if (FlxG.keys.justPressed.RIGHT)
			{
				FlxG.sound.play(Paths.sound('Hover', 'clown'));
				diff += 1;
			}
			if (FlxG.keys.justPressed.LEFT)
			{
				FlxG.sound.play(Paths.sound('Hover', 'clown'));
				diff -= 1;
			}

			if (controls.BACK)
			{
				selectedSmth = true;
				FlxG.sound.play(Paths.sound('Hover', 'clown'));
				FlxG.switchState(new MainMenuState());
			}
		}

		var upperLimit:Int = (songs[selectedIndex].pognt == 'improbable-outset' || songs[selectedIndex].pognt == 'madness') ? 3 : 1;

		if (diff >= upperLimit)
			diff = 0;
		if (diff < 0)
			diff = upperLimit - 1;

		if (diff != curdiff)
		{
			FlxTween.cancelTweensOf(colorSwap);
			FlxTween.tween(colorSwap, {hue: diff == 2 ? upsideOffset : 0}, 0.2);
		}

		curdiff = diff;

		if (!selectedSmth)
		{
			if (FlxG.mouse.justMoved || FlxG.mouse.justPressed)
				lastInput = false;

			if (!lastInput)
				for (i in 0...songs.length)
				{
					if (FlxG.mouse.overlaps(songs[i].spriteOne) || FlxG.mouse.overlaps(songs[i].spriteTwo))
					{
						if (selectedIndex != i)
						{
							songs[selectedIndex].unHighlight();
							selectedIndex = i;
							songs[selectedIndex].highlight();
						}

						if (FlxG.mouse.justPressed && !selectedSmth)
						{
							selectedSmth = true;
							songs[i].select(diff == 2);
						}
					}
				}

			if (FlxG.keys.justPressed.DOWN)
			{
				lastInput = true;
				if (selectedIndex + 1 < songs.length)
				{
					songs[selectedIndex].unHighlight();
					songs[selectedIndex + 1].highlight();
					selectedIndex++;
				}
				else
				{
					songs[selectedIndex].unHighlight();
					selectedIndex = 0;
					songs[selectedIndex].highlight();
				}
			}
			if (FlxG.keys.justPressed.UP)
			{
				lastInput = true;
				if (selectedIndex > 0)
				{
					songs[selectedIndex].unHighlight();
					songs[selectedIndex - 1].highlight();
					selectedIndex--;
				}
				else
				{
					songs[selectedIndex].unHighlight();
					songs[songs.length - 1].highlight();
					selectedIndex = songs.length - 1;
				}
			}

			if (FlxG.keys.justPressed.ENTER && !selectedSmth)
			{
				lastInput = true;
				selectedSmth = true;
				songs[selectedIndex].select(diff == 2);
			}
		}
	}

	override function destroy() {
		FlxG.camera.filters = [];
		super.destroy();
	}
}
