package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class WarningSubState extends MusicBeatState
{
	var transitioning:Bool = false;

	var tricky:Character;

	public function new()
	{
		super();
		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('fourth/bg', 'clown'));
		bg.visible = !FlxG.save.data.lowend;
		add(bg);
		tricky = new Character(FlxG.width / 2, FlxG.height / 2, 'TrickyMask');
		tricky.scale.set(0.5, 0.5);
		tricky.alpha = 0.5;
		tricky.shader = null;
		tricky.updateHitbox();
		tricky.screenCenter(X);
		add(tricky);

		var txt:FlxText = new FlxText(0, 0, FlxG.width, "
				Warning
			\n this is a MOD for
			\n Both old and new BeatStreets and Upside Remixes
			\n press enter to continue" // \n press backspace to see the original"
			, 32);

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
				FlxG.save.data.Warned = true;
				FlxG.camera.flash(FlxColor.GRAY, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				FlxG.sound.music.fadeOut(1, 0);
				new FlxTimer().start(1.4, function(tmr:FlxTimer)
				{
					MainMenuState.reRoll();
					FlxG.switchState(new MainMenuState());
				});
				transitioning = true;
			}
			// if (FlxG.keys.justPressed.BACKSPACE)
			// FlxG.openURL('https://gamebanana.com/mods/43994');
		}
		super.update(elapsed);
	}
}
