package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

class WarningSubState extends MusicBeatState
{
	var transitioning:Bool = false;

	var tricky:FlxSprite;

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('fourth/bg', 'clown'));
		add(bg);
		tricky = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
		tricky.frames = Paths.getSparrowAtlas('TrickyMask');
		// tricky.frames = Paths.getSparrowAtlas('TrickyMask', 'clown');
		tricky.setGraphicSize(Std.int(tricky.width * 0.5));
		tricky.alpha = 0.5;
		tricky.animation.addByPrefix('Idle', 'Idle', 24, true);
		tricky.animation.addByPrefix('singUP', 'Sing Up', 24);
		tricky.animation.addByPrefix('singRIGHT', 'Sing Right', 24);
		tricky.animation.addByPrefix('singDOWN', 'Sing Down', 24);
		tricky.animation.addByPrefix('singLEFT', 'Sing Left', 24);

		tricky.animation.play('Idle');
		tricky.updateHitbox();
		tricky.screenCenter(X);
		add(tricky);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Warning"
			+ "\n this is a fan fixes for"
			+ "\n The Full BeatStreets Tricky Remixes Mod"
			+ "\n press enter to continue"
			+ "\n press backspace to see the original",
			32);

		txt.setFormat("VCR OSD Mono", 32, CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER || FlxG.mouse.justPressed)
		{
			new FlxTimer().start(1.4, function(tmr:FlxTimer)
			{
				FlxG.switchState(new MainMenuState());
			});
			FlxG.camera.flash(FlxColor.GRAY, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			FlxG.sound.music.fadeOut(1, 0);
			transitioning = true;
			if (FlxG.save.data.warningsus1)
			{
				FlxG.save.data.warningsus1 == false;
			}
			switch (FlxG.random.int(1, 4))
			{
				case 2:
					tricky.animation.play('singUP');
				case 3:
					tricky.animation.play('singRIGHT');
				case 4:
					tricky.animation.play('singDOWN');
				default:
					tricky.animation.play('singLEFT');
			}
		}
		if (FlxG.keys.justPressed.BACKSPACE)
		{
			FlxG.openURL('https://gamebanana.com/mods/43994');
		}
		super.update(elapsed);
	}
}
