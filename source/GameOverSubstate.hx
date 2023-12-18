package;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import lime.app.Application;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxObject;

	var bg:FlxSprite;
	var bgblack:FlxSprite;

	var stageSuffix:String = "";

	public function new(x:Float, y:Float)
	{
		var daStage = PlayState.curStage;
		var daBf:String = 'signDeath';

		super();

		Conductor.songPosition = 0;

		if (!FlxG.save.data.lowend)
		{
			bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(23, 23, 23));
			bg.scale.scale(1 / FlxG.camera.zoom);
			bg.scrollFactor.set();
			add(bg);
			bgblack = new FlxSprite().makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.BLACK);
			bgblack.setPosition(FlxG.width / 4, FlxG.height / 4);
			bgblack.scale.scale(1 / FlxG.camera.zoom);
			bgblack.scrollFactor.set();
			bgblack.alpha = 0;
			add(bgblack);

			FlxTransWindow.getWindowsTransparent();
			Application.current.window.borderless = true;
		}

		bf = new Boyfriend(x, y, daBf);
		add(bf);
		if (FlxG.save.data.Shaders)
			bf.chromaticabberation.setChrome(0);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x - 100, bf.getGraphicMidpoint().y - 100, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('Beatstreets/BF_Deathsound', 'clown'));
		FlxG.sound.play(Paths.sound('Beatstreets/Micdrop', 'clown'));
		Conductor.changeBPM(200);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		FlxG.camera.follow(camFollow, LOCKON, 1);

		bf.playAnim('firstDeath');
		bf.animation.resume();
	}

	var playedMic:Bool = false;

	override function update(elapsed:Float)
	{
		FlxG.camera.zoom = 0.9;

		super.update(elapsed);

		if (controls.ACCEPT)
		{
			Main.fpsCounter.visible = FlxG.save.data.fps;
			endBullshit();
		}

		if (controls.BACK)
		{
			Main.fpsCounter.visible = FlxG.save.data.fps; 
			if (!FlxG.save.data.lowend)
			{
				FlxTransWindow.getWindowsbackward();
				Application.current.window.borderless = false;
			}
			FlxG.sound.music.stop();
			MainMenuState.reRoll = true;
			FlxG.switchState(new MainMenuState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			FlxG.sound.playMusic(Paths.music('gameOver', 'clown'));
			bf.playAnim('deathLoop', true);
		}
		else if (bf.animation.curAnim.finished && bf.animation.curAnim.name != 'deathConfirm')
		{
			bf.playAnim('deathLoop', true);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			if (!FlxG.save.data.lowend)
				FlxTween.tween(bgblack, {alpha: 1}, 0.4);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music('gameOverEnd', 'clown'));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				if (!FlxG.save.data.lowend)
				{
					FlxTransWindow.getWindowsbackward();
					Application.current.window.borderless = false;
				}
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
