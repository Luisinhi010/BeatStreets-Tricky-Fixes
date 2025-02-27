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

class GameOverSubstate extends MusicBeatSubstate {
    var camFollow:FlxObject;
    var bg:FlxSprite;
    var bf:Character;
    var gameOverMusic:FlxSound;
    var isUpside:Bool;

    public function new() {
        super();

        Conductor.songPosition = 0;
        bf = PlayState.staticVar.deadbf;
        isUpside = PlayState.SONG.song.endsWith('-upside');

        if (!FlxG.save.data.lowend && !PlayState.staticVar.songData.isClassic)
        {
            bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
            bg.color = FlxColor.fromRGB(23, 23, 23);
            bg.scale.set(1 / FlxG.camera.zoom, 1 / FlxG.camera.zoom);
            bg.scrollFactor.set();
            add(bg);
            setWindowState(true);
        }

        add(bf);

        camFollow = new FlxObject(bf.getGraphicMidpoint().x - 100, bf.getGraphicMidpoint().y - 100);
        add(camFollow);

        FlxG.sound.play(Paths.sound('Beatstreets/BF_Deathsound', 'clown'));

        Conductor.changeBPM(isUpside ? 100 : 200);

        FlxG.camera.target = null;
        FlxG.camera.follow(camFollow, LOCKON, 1);

        bf.playAnim('firstDeath');
        bf.animation.resume();
    }

    function setWindowState(isTransparent:Bool):Void
		{
			if (!FlxG.save.data.lowend && !PlayState.staticVar.songData.isClassic) {
				if (isTransparent)
					FlxTransWindow.getWindowsTransparent();
				else
					FlxTransWindow.getWindowsbackward();
				Application.current.window.borderless = isTransparent;
			}
		}

    var playedMic:Bool = false;
    override function update(elapsed:Float) {
        try {
            FlxG.camera.zoom = 0.9;

            if (!playedMic && halfupdate) {
                new FlxTimer().start(0.7, (tmr:FlxTimer) -> FlxG.sound.play(Paths.sound('Beatstreets/Micdrop', 'clown')));
                playedMic = true;
            }

            super.update(elapsed);

            if (controls.ACCEPT) {
                restartGame();
            } else if (controls.BACK) {
                Main.fpsCounter.visible = Main.debug.visible = true;
                setWindowState(false);
                cancelMusic();
                FlxG.switchState(new MainMenuState());
            }

            if (bf.animation.curAnim.finished) {
                if (bf.animation.curAnim.name == 'firstDeath') {
                    playGameOverMusic();
                    bf.playAnim('deathLoop', true);
                } else if (bf.animation.curAnim.name != 'deathConfirm' && !isUpside)
                    bf.playAnim('deathLoop', true);
            }

            if (FlxG.sound.music.playing)
                Conductor.songPosition = FlxG.sound.music.time;
        } catch (e:Dynamic) {
            trace('Update error: $e');
            throw 'Update error: $e';
        }
    }

    inline function cancelMusic():Void {
        FlxG.sound.music.stop();
        FlxG.autoPause = true;
        PlayState.deathCounter = 0;
        MainMenuState.reRoll();
    }

    function playGameOverMusic():Void {
        gameOverMusic = new FlxSound().loadEmbedded(Paths.music(isUpside ? 'upside/gameOver-intro' : 'gameOver', 'clown'), !isUpside, isUpside);
        gameOverMusic.play();

        if (isUpside) {
            gameOverMusic.onComplete = () -> {
                gameOverMusic.stop();
                gameOverMusic = new FlxSound().loadEmbedded(Paths.music('upside/gameOver-loop', 'clown'), true, false);
                gameOverMusic.play();
                gameOverMusic.onComplete = null;
            };
        }
    }

    var isEnding:Bool = false;
    override function beatHit() {
        super.beatHit();
        if (isUpside) bf.playAnim('deathLoop', true);
    }

    function restartGame():Void {
        if (isEnding) return;

        isEnding = true;
        bf.playAnim('deathConfirm', true);

        var musicPath = isUpside ? 'upside/gameOverEnd' : 'gameOverEnd';
        gameOverMusic.stop();
        gameOverMusic = new FlxSound().loadEmbedded(Paths.music(musicPath, 'clown'), false, true);
        gameOverMusic.play();
        gameOverMusic.onComplete = null;

        if (isUpside && PlayState.staticVar.songData.isClassic)
            flixel.effects.FlxFlicker.flicker(bf, 2.7, 0.20, true);
        else
        {
            bg.color = FlxColor.WHITE;
            setWindowState(false);
            FlxTween.color(bg, 1, bg.color, FlxColor.BLACK);
        }

        new FlxTimer().start(0.7, function(tmr:FlxTimer) {
            FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
                LoadingState.loadAndSwitchState(new PlayState());
            });
        });
    }
}
