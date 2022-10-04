package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class WarningSubState extends MusicBeatState
{
	var transitioning:Bool = false;

	var tricky:FlxSprite;

	public function new()
	{
		super();
		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('fourth/bg', 'clown'));
		bg.visible = !FlxG.save.data.lowend;
		add(bg);
		tricky = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
		tricky.frames = Paths.getSparrowAtlas('TrickyMask');
		// tricky.frames = Paths.getSparrowAtlas('TrickyMask', 'clown');
		tricky.setGraphicSize(Std.int(tricky.width * 0.5));
		if (!FlxG.save.data.lowend)
			tricky.alpha = 0.5;
		tricky.antialiasing = !FlxG.save.data.lowend;
		tricky.animation.addByPrefix('Idle', 'Idle', 24, true);
		tricky.animation.addByPrefix('singUP', 'Sing Up', 24);
		tricky.animation.addByPrefix('singRIGHT', 'Sing Right', 24);
		tricky.animation.addByPrefix('singDOWN', 'Sing Down', 24);
		tricky.animation.addByPrefix('singLEFT', 'Sing Left', 24);

		tricky.animation.play('Idle');
		tricky.updateHitbox();
		tricky.screenCenter(X);
		add(tricky);

		#if debug
		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Warning"
			+ "\n this is a debug version of the"
			+ "\n fan fixes for"
			+ "\n The Full BeatStreets Tricky Remixes Mod"
			+ "\n press enter to continue"
			+ "\n press backspace to see the original",
			32);
		#end
		#if !debug
		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Warning"
			+ "\n this is a fan fixes for"
			+ "\n The Full BeatStreets Tricky Remixes Mod"
			+ "\n press enter to continue"
			+ "\n press backspace to see the original",
			32);
		#end

		txt.setFormat("VCR OSD Mono", 32, CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (!transitioning)
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
				FlxG.save.data.Warned = true;

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
				FlxG.openURL('https://gamebanana.com/mods/43994');
		}
		super.update(elapsed);
	}
}
