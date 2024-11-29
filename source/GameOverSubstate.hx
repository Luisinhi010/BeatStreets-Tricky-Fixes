package;

import flixel.sound.FlxSound;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import lime.app.Application;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class GameOverSubstate extends MusicBeatSubstate
{
	var camFollow:FlxObject;

	var bg:FlxSprite;

	var bf:Boyfriend;

	var stageSuffix:String = "";

	var temp:FlxSound;

	public function new()
	{
		super();

		Conductor.songPosition = 0;

		bf = PlayState.staticVar.deadbf;

		if (!FlxG.save.data.lowend && !PlayState.staticVar.classic)
		{
			bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(23, 23, 23));
			bg.scale.scale(1 / FlxG.camera.zoom);
			bg.scrollFactor.set();
			add(bg);

			FlxTransWindow.getWindowsTransparent();
			Application.current.window.borderless = true;
		}

		add(bf);

		camFollow = new FlxObject(bf.getGraphicMidpoint().x - 100, bf.getGraphicMidpoint().y - 100, 1, 1);
		add(camFollow);

		FlxG.sound.play(Paths.sound('Beatstreets/BF_Deathsound', 'clown'));
		if (PlayState.SONG.song.endsWith('-upside'))
		{
			temp = new FlxSound().loadEmbedded(Paths.music('upside/gameOver-loop', 'clown'), true, true);
			Conductor.changeBPM(100);
		}
		else
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

		if (!playedMic && halfupdate)
		{
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.sound.play(Paths.sound('Beatstreets/Micdrop', 'clown'));
			});
			playedMic = true;
		}

		super.update(elapsed);

		if (controls.ACCEPT)
		{
			Main.fpsCounter.visible = FlxG.save.data.fps;
			Main.debug.visible = true;
			endBullshit();
		}

		if (controls.BACK)
		{
			Main.fpsCounter.visible = FlxG.save.data.fps;
			Main.debug.visible = true;
			if (!FlxG.save.data.lowend && !PlayState.staticVar.classic)
			{
				FlxTransWindow.getWindowsbackward();
				Application.current.window.borderless = false;
			}
			FlxG.autoPause = true;
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			MainMenuState.reRoll();
			FlxG.switchState(new MainMenuState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			if (PlayState.SONG.song.endsWith('-upside'))
			{
				FlxG.sound.playMusic(Paths.music('upside/gameOver-intro', 'clown'), 1.0, false);
				FlxG.sound.music.onComplete = function()
				{
					@:privateAccess
					FlxG.sound.playMusic(temp._sound);
					FlxG.sound.music.onComplete = null;
				}
			}
			else
				FlxG.sound.playMusic(Paths.music('gameOver', 'clown'));
			FlxG.autoPause = false;
			bf.playAnim('deathLoop', true);
		}
		else if (bf.animation.curAnim.finished && bf.animation.curAnim.name != 'deathConfirm' && !PlayState.SONG.song.endsWith('-upside'))
		{
			bf.playAnim('deathLoop', true);
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
	}

	var isEnding:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if (PlayState.SONG.song.endsWith('-upside'))
			bf.playAnim('deathLoop', true);
	}

	override function destroy()
	{
		if (temp != null)
			temp.destroy();
		// FlxG.sound.music.destroy(); // memory leak fix?

		super.destroy();
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			if (PlayState.SONG.song.endsWith('-upside'))
			{
				FlxG.sound.play(Paths.music('upside/gameOverEnd', 'clown'));
				FlxG.sound.music.onComplete = null; // to be sure...
				if (PlayState.staticVar.classic)
					flixel.effects.FlxFlicker.flicker(bf, 2.7, 0.20, true);
			}
			else
				FlxG.sound.play(Paths.music('gameOverEnd', 'clown'));
			FlxG.autoPause = true;
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					if (!FlxG.save.data.lowend && !PlayState.staticVar.classic)
					{
						FlxTransWindow.getWindowsbackward();
						Application.current.window.borderless = false;
					}
					LoadingState.loadAndSwitchState(new PlayState());
				});
			});
		}
	}
}
