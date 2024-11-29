package;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

using StringTools;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var selectedSmth = false;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var temp:FlxSound;

	var bg:LuisSprite = new LuisSprite();
	var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.staticVar.songName, 32);
	var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, CoolUtil.difficultyString(), 32);
	var deaths:FlxText = new FlxText(20, 15 + 64, 0, "Died: " + PlayState.deathCounter, 32);

	public function new()
	{
		super();
		FlxG.autoPause = false;

		if (PlayState.SONG.song.endsWith('-upside'))
		{
			pauseMusic = new FlxSound().loadEmbedded(Paths.music('upside/breakfast-intro', 'clown'), false, true);
			temp = new FlxSound().loadEmbedded(Paths.music('upside/breakfast-loop', 'clown'), true, true);
			pauseMusic.play(true);
			pauseMusic.onComplete = function()
			{
				var lastvolume:Float = pauseMusic.volume;
				pauseMusic = temp;
				pauseMusic.volume = lastvolume;
				pauseMusic.play(true);
				pauseMusic.onComplete = null;
			}
		}
		else
		{
			pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast', 'shared'), true, true);
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		}
		pauseMusic.volume = 0;

		FlxG.sound.list.add(pauseMusic);

		bg.makeGraphic(1, 1, FlxColor.WHITE);
		bg.color = FlxColor.BLACK;
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		deaths.scrollFactor.set();
		deaths.setFormat(Paths.font('vcr.ttf'), 32);
		deaths.updateHitbox();
		add(deaths);

		deaths.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		deaths.x = FlxG.width - (deaths.width + 20);

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [PlayState.staticVar.camHUD];
	}

	var tweenstarted:Bool = false;

	override function update(elapsed:Float)
	{
		if (pauseMusic?.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if (!tweenstarted) // im so sorry for you who are reading this code
		{
			FlxTween.tween(bg, {alpha: 0.6}, 0.4, {
				ease: FlxEase.quartInOut,
				onStart: (tween:FlxTween) ->
				{
					tweenstarted = true;
				}
			});
			FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			FlxTween.tween(deaths, {alpha: 1, y: deaths.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		}

		if (!selectedSmth)
		{
			var upP = controls.UP_P;
			var downP = controls.DOWN_P;
			var accepted = controls.ACCEPT;
			var back = controls.BACK;

			if (upP)
				changeSelection(-1);
			if (downP)
				changeSelection(1);

			if (accepted)
			{
				var daSelected:String = menuItems[curSelected];

				switch (daSelected)
				{
					case "Resume":
						unpause();
					case "Restart Song":
						FlxG.resetState();
					case "Exit to menu":
						MainMenuState.reRoll();
						FlxG.switchState(new MainMenuState());
				}
			}

			if (back)
				unpause();
		}
	}

	override function destroy()
	{
		if (temp != null)
			temp.destroy();
		pauseMusic.onComplete = null;
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}

	function unpause()
	{
		selectedSmth = true;
		FlxG.autoPause = true;
		if (FlxG.keys.pressed.CONTROL)
			return close();

		var swagCounter:Int = 1;
		for (member in members)
			if (member is flixel.FlxObject)
			{
				FlxTween.cancelTweensOf(member);
				FlxTween.tween(member, {alpha: 0}, PlayState.beatTime);
			}
		for (member in grpMenuShit.members)
			FlxTween.tween(member, {alpha: 0}, PlayState.beatTime); // :skull:

		PlayState.staticVar.countdown(0);
		new FlxTimer().start(PlayState.beatTime, function(tmr:FlxTimer)
		{
			PlayState.staticVar.countdown(swagCounter);
			if (swagCounter == 4)
				close();

			swagCounter += 1;
		}, 5);
	}
}
