package;

import flixel.util.FlxGradient;
import Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	var luis:FlxSprite;

	var curWacky:Array<String> = [];

	override public function create():Void
	{
		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		#if desktop
		CppAPI.darkMode();
		#end

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		logoBl = new FlxSprite(-200, -160);
		logoBl.frames = Paths.getSparrowAtlas('TrickyLogo', 'clown');
		logoBl.antialiasing = !FlxG.save.data.lowend;
		logoBl.animation.addByPrefix('bump', 'Logo', 34);
		logoBl.animation.play('bump');
		logoBl.setGraphicSize(Std.int(logoBl.width * 0.5));
		logoBl.updateHitbox();

		gfDance = new FlxSprite(FlxG.width * 0.23, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('DJ_Tricky', 'clown');
		gfDance.animation.addByPrefix('dance', 'mixtape', 24, true);
		gfDance.antialiasing = !FlxG.save.data.lowend;
		gfDance.setGraphicSize(Std.int(gfDance.width * 0.6));

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = !FlxG.save.data.lowend;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);

		credGroup = new FlxGroup();
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		luis = new FlxSprite(0, FlxG.height * 0.55).loadGraphic(Paths.image('Luis', 'clown'));
		luis.visible = false;
		luis.setGraphicSize(Std.int(luis.width * 0.5));
		luis.updateHitbox();
		luis.screenCenter(X);
		luis.y -= 100;
		luis.antialiasing = !FlxG.save.data.lowend;

		if (/*!FlxG.save.data.lowend &&*/ !CachedFrames.loaded)
			CachedFrames.loadEverything();

		Highscore.load();

		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		#else
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		if (!initialized)
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			// var test:FlxGraphic = FlxGraphic.fromAssetKey(Paths.image('loadingButNotDone', 'clown'));
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-2000, -200, FlxG.width * 5, FlxG.height * 3));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-2000, -200, FlxG.width * 5, FlxG.height * 3));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;
			FlxG.sound.playMusic(Paths.music('Tiky_Demce', 'clown'), 0);

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(139);
		}

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('fourth/bg', 'clown'));
		bg.antialiasing = !FlxG.save.data.lowend;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();

		add(bg);
		add(gfDance);
		add(logoBl);
		add(titleText);
		add(credGroup);
		add(luis);

		KadeEngineData.initSave();

		FlxG.mouse.visible = true;

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [[]];

		for (i in firstArray)
			swagGoodArray.push(i.split('--'));

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	public static var once:Bool = false;

	override function update(elapsed:Float)
	{
		if (!once)
		{
			once = true;
			new FlxTimer().start(.2, function(tmr:FlxTimer)
			{
				canSkip = true;
				startIntro();
			});
		}
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		if (FlxG.mouse.justPressed)
			pressedEnter = true;

		#if mobile
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				pressedEnter = true;
		#end

		if (pressedEnter && !transitioning && skippedIntro)
		{
			titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.BLUE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;

			if (FlxG.save.data.Warned)
				FlxG.sound.music.fadeOut(1, 0);

			new FlxTimer().start(1.4, function(tmr:FlxTimer)
			{
				if (!FlxG.save.data.Warned)
					FlxG.switchState(new WarningSubState());
				else{
					MainMenuState.reRoll();
					FlxG.switchState(new MainMenuState());
				}
			});
		}

		if (pressedEnter && !skippedIntro && CachedFrames.loaded && canSkip) // its better a kinda fake loading than a pause to load everthing.
			skipIntro();

		super.update(elapsed);
		FlxG.camera.zoom = flixel.math.FlxMath.lerp(1, FlxG.camera.zoom, 0.95);
	}

	var canSkip = false;

	function createCoolText(textArray:Array<String>, yOffset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			if (yOffset != 0)
				money.y -= yOffset;
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addCustomText(text:String, yOffset:Float = 0)
	{
		var coolText:Alphabet = new Alphabet(0, (textGroup.length * 60) + 200, text, true, false);
		coolText.screenCenter(X);
		if (yOffset != 0)
			coolText.y -= yOffset;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function addMoreText(text:String, yOffset:Float = 0)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		if (yOffset != 0)
			coolText.y -= yOffset;
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (!skippedIntro)
			FlxG.camera.zoom += 0.015;

		logoBl.animation.play('bump');

		gfDance.animation.play('dance');

		FlxG.log.add(curBeat);

		switch (curBeat)
		{
			case 5:
				addCustomText('Luisinho010', 135);
			case 6:
				addCustomText('Fully', 135);
			case 7:
				addCustomText('Appresents', 135);
				luis.visible = true;
			case 8:
				deleteCoolText();
				luis.visible = false;
			case 9:
				addCustomText('A Mod');
			case 10:
				addCustomText('Of Mods');
			case 11:
				addCustomText('From Stranges Moders');
			case 12:
				deleteCoolText();
			case 13:
				addCustomText('I love you');
			case 14:
				addCustomText('My Dear');
			case 15:
				addCustomText('Player');
			case 16:
				deleteCoolText();
			case 17:
				addCustomText(curWacky[0]);
			case 18:
				addCustomText(curWacky[1]);
			case 19:
				deleteCoolText();
			case 20:
				curWacky = FlxG.random.getObject(getIntroTextShit());
				addCustomText(curWacky[0]);
			case 21:
				addCustomText(curWacky[1]);
			case 22:
				deleteCoolText();
			case 23:
				curWacky = FlxG.random.getObject(getIntroTextShit());
				addCustomText(curWacky[0]);
			case 24:
				addCustomText(curWacky[1]);
			case 25:
				deleteCoolText();
			case 26:
				curWacky = FlxG.random.getObject(getIntroTextShit());
				addCustomText(curWacky[0]);
			case 27:
				addCustomText(curWacky[1]);
			case 28:
			case 29:
				deleteCoolText();
				addCustomText('Drop');
			case 30:
				addCustomText('The beat');
			case 31:
				addCustomText('And enjoy it');
			case 32:
				deleteCoolText();
				skipIntro();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(luis);
			PlayerSettings.player1.controls.loadKeyBinds();
			FlxG.camera.flash(FlxColor.BLUE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
