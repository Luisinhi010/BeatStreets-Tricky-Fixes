package;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var slider:FlxBackdrop;

	public static var killed:Bool = false;
	public static var show:String = "bf";
	public static var playingshowermusic:Bool = false;

	var hand:LuisSprite;
	var shower:FlxSprite;

	public static var trans:FlxSprite;

	var clownButton:TrickyButton;

	public var listOfButtons:Array<TrickyButton> = [
		new TrickyButton(765, 160, 'menu/Clown Mode Button', 'menu/Clown Mode Button CONFIRM', playStory, 'clown', 0, -40),
		new TrickyButton(975, 165, 'menu/FreePlayButton', 'menu/FreePlayButton CONFIRM', goToFreeplay, "free", 0, -40),
		new TrickyButton(975, 460, 'menu/OPTIONS Button', 'menu/OPTIONS Button CONFIRM', goToOptions, "options", 0, 45)
	];
	public var lastInput:Bool = true;

	var tinyMan:FlxSprite;
	var tinyManHit:FlxSprite;
	var text:FlxText = new FlxText(0, 0, '');
	var textTween:FlxTween;

	var chromaticabberation:Shaders.ChromaticAberrationEffect;

	var lines:Array<String> = [];

	override function create()
	{
		lines = CoolUtil.coolTextFile(Paths.txt('tinyTrickyLines', 'clown'));

		if (FlxG.save.data.beatenHard)
		{
			listOfButtons[1].spriteOne = new FlxSprite(listOfButtons[1].spriteOne.x,
				listOfButtons[1].spriteOne.y).loadGraphic(Paths.image("menu/FreePlayEX", 'clown'));
			listOfButtons[1].spriteTwo = new FlxSprite(listOfButtons[1].spriteTwo.x,
				listOfButtons[1].spriteTwo.y).loadGraphic(Paths.image("menu/FreePlayEX_Confirm", 'clown'));
		}

		trans = new FlxSprite(-300, -760);
		trans.frames = Paths.getSparrowAtlas('Jaws', 'clown');
		trans.antialiasing = !FlxG.save.data.lowend;
		trans.visible = !FlxG.save.data.lowend;

		trans.animation.addByPrefix("Close", "Jaws smol", 24, false);

		trans.setGraphicSize(Std.int(trans.width * 1.38));

		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/RedBG', 'clown'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.y += 40;
		add(bg);
		var hedgeBG:FlxSprite = new FlxSprite(-750, 110).loadGraphic(Paths.image('menu/HedgeBG', 'clown'));
		hedgeBG.setGraphicSize(Std.int(hedgeBG.width * 0.65));
		add(hedgeBG);
		var foreground:FlxSprite = new FlxSprite(-750, 110).loadGraphic(Paths.image('menu/Transforeground', 'clown'));
		foreground.setGraphicSize(Std.int(foreground.width * 0.65));
		foreground.visible = !FlxG.save.data.lowend;
		add(foreground);
		slider = new FlxBackdrop(Paths.image('menu/MenuSlider', 'clown'), FlxAxes.X);
		slider.velocity.set(-8, 0);
		slider.x = -20;
		slider.y = 209;
		slider.setGraphicSize(Std.int(slider.width * 0.65));
		slider.visible = !FlxG.save.data.lowend;
		add(slider);

		trace('im showin ' + show);

		if (FlxG.save.data.lowend)
			killed = true;

		shower = new FlxSprite(200, 280);

		Conductor.changeBPM(165);

		chromaticabberation = new Shaders.ChromaticAberrationEffect();
		chromaticabberation.multiplier = 0.0002;
		slider.shader = chromaticabberation.shader;

		switch (show)
		{
			case 'bf':
				shower.frames = Paths.getSparrowAtlas("menu/MenuBF/MenuBF", 'clown');
				shower.animation.addByPrefix('idle', 'BF idle menu', 24, false);
				shower.flipX = true;

				shower.setGraphicSize(Std.int(shower.width * 0.76));
				shower.x -= 50;

			case 'tricky':
				shower.frames = Paths.getSparrowAtlas("menu/MenuTricky/MenuTricky", 'clown');
				shower.animation.addByPrefix('idle', 'Tricky Idle menu instance');
				shower.y -= 155;
				shower.x -= 100;

				shower.setGraphicSize(Std.int(shower.width * 0.76));

				shower.shader = chromaticabberation.shader;
			case 'sus':
				shower.frames = Paths.getSparrowAtlas("menu/Sus/Menu_ALLSUS", 'clown');
				shower.animation.addByPrefix('idle', 'AmongUsIDLE', 24);
				shower.animation.addByPrefix('death', 'AMONG DEATH', 24, false);
				shower.animation.addByIndices('deathPost', 'AMONG DEATH', [5], "", 24, false);
				shower.animation.addByPrefix('no', 'AmongUs NuhUh', 24, false);

				shower.setGraphicSize(Std.int(shower.width * 0.76));

				shower.y += 35;
				shower.x += 20;

				hand = new LuisSprite(shower.x + 75, shower.y + 50);
				hand.loadGraphic(Paths.image('menu/Sus/AmongHand', 'clown'));
				hand.setGraphicSize(Std.int(hand.width * 0.67));
				hand.antialiasing = !FlxG.save.data.lowend;
				hand.alpha = 0;

				lines.push('');

			case 'jebus':
				shower.frames = Paths.getSparrowAtlas("menu/Jebus/Menu_jebus", 'clown');
				shower.animation.addByPrefix('idle', 'Jebus');
				shower.y -= 240;
				shower.x -= 135;

				shower.setGraphicSize(Std.int(shower.width * 0.66));

			case 'hank':
				shower.frames = Paths.getSparrowAtlas("menu/Hank/Hank_Menu", 'clown');
				shower.animation.addByPrefix('idle', 'Hank');
				shower.y -= 240;
				shower.x -= 160;

				shower.setGraphicSize(Std.int(shower.width * 0.63));

				shower.shader = chromaticabberation.shader;
			case 'deimos':
				shower.frames = Paths.getSparrowAtlas("menu/Deimos/Deimos_Menu", 'clown');
				shower.animation.addByPrefix('idle', 'Deimos');

				shower.setGraphicSize(Std.int(shower.width * 0.68));
				shower.y -= 65;
				shower.x -= 125;
				shower.angle = -8;

				shower.shader = chromaticabberation.shader;
			case 'auditor':
				shower.frames = Paths.getSparrowAtlas("menu/Auditor/Auditor", 'clown');
				shower.animation.addByPrefix('idle', 'Auditor');

				shower.y -= 300;
				shower.x -= 190;
				shower.setGraphicSize(Std.int(shower.width * 0.76));

			case 'mag':
				shower.frames = Paths.getSparrowAtlas("menu/Torture/Mag_Agent_Torture_Menu", 'clown');
				shower.animation.addByPrefix('idle', 'Mag Agent Torture');

				shower.setGraphicSize(Std.int(shower.width * 0.66));
				shower.y -= 310;
				shower.x -= 480;

			case 'sanford':
				shower.frames = Paths.getSparrowAtlas("menu/Sanford/Menu_Sanford", 'clown');
				shower.animation.addByPrefix('idle', 'Sanford');

				shower.setGraphicSize(Std.int(shower.width * 0.66));
				shower.y -= 180;
				shower.x -= 255;

				shower.shader = chromaticabberation.shader;
		}

		if (!FlxG.sound.music.playing)
		{
			trace('going to play ' + show);
			FlxG.sound.playMusic(Paths.music("menu/nexus_" + show, 'clown'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		if (openfl.utils.Assets.exists(Paths.txt('lines/' + show, 'clown'), TEXT))
			lines.push(lime.utils.Assets.getText(Paths.txt('lines/' + show, 'clown')).trim());
		else
			trace('doesnt seens to exist: lines/' + show + '.txt');

		shower.antialiasing = !FlxG.save.data.lowend;
		shower.visible = !FlxG.save.data.lowend;

		if (show == 'sus' && killed && !FlxG.save.data.lowend)
		{
			shower.offset.set(5, 10);
			shower.animation.play('deathPost');
		}
		else if (show != 'bf' && !FlxG.save.data.lowend)
			shower.animation.play('idle');

		for (i in listOfButtons)
		{
			// just general compensation since pasc made this on 1920x1080 and we're on 1280x720
			i.spriteOne.setGraphicSize(Std.int(i.spriteOne.width * 0.7));
			i.spriteTwo.setGraphicSize(Std.int(i.spriteTwo.width * 0.7));
			add(i);
			add(i.spriteOne);
			add(i.spriteTwo);
		}

		add(shower);

		var bgCover:FlxSprite = new FlxSprite(-455, -327).loadGraphic(Paths.image('menu/BGCover', 'clown'));
		bgCover.setGraphicSize(Std.int(bgCover.width * 0.7));
		bgCover.antialiasing = !FlxG.save.data.lowend;
		add(bgCover);

		var hedgeCover:FlxSprite = new FlxSprite(-750, -414).loadGraphic(Paths.image('menu/Hedgecover', 'clown'));
		hedgeCover.setGraphicSize(Std.int(hedgeCover.width * 0.65));
		hedgeCover.antialiasing = !FlxG.save.data.lowend;
		add(hedgeCover);

		var redLines:FlxSprite = new FlxSprite(-749, 98).loadGraphic(Paths.image("menu/MenuRedLines", 'clown'));
		redLines.setGraphicSize(Std.int(redLines.width * 0.7));
		redLines.antialiasing = !FlxG.save.data.lowend;
		add(redLines);

		var logo:FlxSprite = new FlxSprite(-50, -15).loadGraphic(Paths.image("menu/Mainlogo", 'clown'));
		logo.antialiasing = !FlxG.save.data.lowend;
		add(logo);

		if (FlxG.save.data.beatenHard)
		{
			var troph:FlxSprite = new FlxSprite(875, -20).loadGraphic(Paths.image("menu/Gold_Trophy", 'clown'));

			if (FlxG.save.data.beatEx)
			{
				tinyMan = new FlxSprite(980, -100);
				tinyMan.frames = Paths.getSparrowAtlas('menu/Fixed_Tiny_Desk_Tricky', 'clown');

				tinyMan.animation.addByPrefix('idle', 'Tiny Desk Tricky Idle', 24);
				tinyMan.animation.addByPrefix('click', 'Tiny Desk Tricky Click', 24, false);
				tinyMan.animation.addByPrefix('meow', 'Tiny Desk Tricky Meow', 24, false);

				tinyMan.animation.play('idle');

				tinyMan.setGraphicSize(Std.int(tinyMan.width * 0.66));

				tinyMan.antialiasing = !FlxG.save.data.lowend;
				tinyMan.shader = chromaticabberation.shader;
				tinyManHit = new FlxSprite(tinyMan.x + 70, tinyMan.y).makeGraphic(tinyMan.frameWidth - 140, tinyMan.frameHeight - 85, FlxColor.CYAN);
				// add(tinyManHit);

				add(tinyMan);

				text.setFormat('tahoma-bold.ttf', 24, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.visible = false;
				text.alpha = 0;
				add(text);

				troph.antialiasing = !FlxG.save.data.lowend;
				troph.setGraphicSize(Std.int(troph.width * 0.8));

				add(troph);
			}
		}

		if (show == 'sus')
			add(hand);

		var menuShade:FlxSprite = new FlxSprite(-1350, -1190).loadGraphic(Paths.image("menu/Menu Shade", 'clown'));
		menuShade.setGraphicSize(Std.int(menuShade.width * 0.7));
		menuShade.antialiasing = !FlxG.save.data.lowend;
		add(menuShade);

		var credits:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image("menu/CreditsOverlay", 'clown'));
		credits.antialiasing = !FlxG.save.data.lowend;
		add(credits);

		add(trans);
		trans.alpha = 0;

		listOfButtons[selectedIndex].highlight();
		FlxG.mouse.visible = true;

		// var normaltest:NormalMapSprite = new NormalMapSprite(-750, -414, Paths.image('menu/Hedgecover', 'clown'), Paths.image('menu/Hedgecover_n', 'clown'));
		// normaltest.setGraphicSize(Std.int(normaltest.width * 0.65));
		// normaltest.antialiasing = !FlxG.save.data.lowend;
		// add(normaltest);

		super.create();
	}

	public static function reRoll()
	{
		FlxG.sound.music.pause();
		FlxG.sound.music.stop();
		var random = Std.int(FlxG.random.float(0, 10));
		var showOptions = [
			"bf",
			"tricky",
			"deimos",
			"jebus",
			"sanford",
			"hank",
			"auditor",
			"mag",
			"bf",
			"sus"
		];
		show = showOptions[random];

		if (random == 9)
		{
			var subRandom = FlxG.random.float(0, 1);
			if (subRandom > 0.8)
				show = "sus";
			else
				show = "bf";
		}

		if (!FlxG.save.data.lowend)
			killed = false;

		trace('random ' + random);
	};

	public static function goToFreeplay()
		FlxG.switchState(new FreeplayState());

	public static function goToOptions()
	{
		FlxG.mouse.visible = false;
		FlxG.switchState(new OptionsMenu());
	}

	public static function playStory()
	{
		FlxG.mouse.visible = false;
		PlayState.storyPlaylist = ['Improbable Outset', 'madness', 'hellclown'];
		PlayState.isStoryMode = true;

		PlayState.SONG = Song.loadFromJson('improbable-outset', 'improbable-outset');
		PlayState.campaignScore = 0;

		FlxG.sound.music.fadeOut();

		PlayState.playCutscene = true;

		trans.animation.play("Close");
		trans.alpha = 1;
		var snd = new FlxSound().loadEmbedded(Paths.sound('swipe', 'clown'));
		snd.play();

		var once = false;

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			if (trans.animation.frameIndex == 10 && !once)
			{
				once = true;
				FlxG.sound.music.volume = 1;
				var snd = new FlxSound().loadEmbedded(Paths.sound('clink', 'clown'));
				snd.play();
			}
			if (trans.animation.frameIndex == 18)
			{
				trans.animation.pause();
				LoadingState.loadAndSwitchState(new PlayState(), true);
			}
			else
				tmr.reset(0.01);
		});
	}

	var selectedSmth = false;

	public static var selectedIndex = 0;

	function doHand()
	{
		shower.animation.play('no');

		var selected = listOfButtons[selectedIndex].spriteTwo;

		FlxTween.cancelTweensOf(hand);
		FlxTween.tween(hand, {alpha: 1, x: selected.x + 10, y: selected.y - 10}, 0.6, {ease: FlxEase.expoInOut});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		if (tinyMan != null && tinyManHit != null && FlxG.mouse.justPressed && tinyMan.animation.curAnim.name == 'idle')
		{
			if (FlxG.mouse.overlaps(tinyMan) && FlxG.mouse.overlaps(tinyManHit))
			{
				var random = FlxG.random.int(0, 50);
				if (random < 45)
				{
					tinyMan.offset.set(33, 9);
					tinyMan.animation.play('click');

					text.text = lines[FlxG.random.int(0, lines.length - 1)];
					text.visible = true;
					text.alpha = 1;
					text.setPosition(tinyMan.x - 200, tinyMan.y + 285);

					if (textTween != null)
						textTween.cancel();

					textTween = FlxTween.tween(text, {alpha: 0}, 0.7, {
						onComplete: function(twn:FlxTween)
						{
							text.visible = false;
							textTween = null;
						}
					});
				}
				else
				{
					tinyMan.offset.set(5, -1);
					FlxG.sound.play(Paths.sound('Meow', 'clown'));
					tinyMan.animation.play('meow');
				}
			}
		}

		if (tinyMan?.animation.finished && tinyMan.animation.curAnim.name != 'idle')
		{
			tinyMan.offset.set(0, 0);
			tinyMan.animation.play('idle');
		}

		if (FlxG.mouse.justMoved || FlxG.mouse.justPressed)
			lastInput = false;

		if (!lastInput)
			for (i in 0...listOfButtons.length)
			{
				if (FlxG.mouse.overlaps(listOfButtons[i].spriteOne) || FlxG.mouse.overlaps(listOfButtons[i].spriteTwo))
				{
					if (selectedIndex != i)
					{
						if (show == 'sus' && !killed && hand.alpha == 1)
							FlxTween.tween(hand, {alpha: 0, x: shower.x + 60, y: shower.y + 60}, 0.6, {ease: FlxEase.expoInOut});
						listOfButtons[selectedIndex].unHighlight();
						selectedIndex = i;
						listOfButtons[selectedIndex].highlight();
						trace('selected ' + selectedIndex);
					}

					if (FlxG.mouse.justPressed)
					{
						if (show == 'sus' && !killed)
						{
							doHand();
							return;
						}
						selectedSmth = true;
						listOfButtons[selectedIndex].select();
					}
				}
			}

		if (show == 'sus' && !killed && shower.animation.finished)
			shower.animation.play('idle');
		else if (show == 'sus' && FlxG.mouse.overlaps(shower) && FlxG.mouse.justPressed && !killed)
		{
			shower.offset.set(5, 10);
			shower.animation.play('death');
			killed = true;
			chromaticabberation.multiplier = 0.002;
			FlxTween.tween(chromaticabberation, {multiplier: 0.0002}, 0.5);
			FlxG.sound.play(Paths.sound('AmongUs-Kill', 'clown'));
			if (hand.alpha == 1)
				FlxTween.tween(hand, {y: FlxG.height + 20 + hand.height, angle: 125, alpha: 0}, 5, {ease: FlxEase.expoOut});
		}
		if (FlxG.keys.justPressed.RIGHT)
		{
			lastInput = true;
			if (show == 'sus' && !killed && hand.alpha == 1)
				FlxTween.tween(hand, {alpha: 0, x: shower.x + 60, y: shower.y + 60}, 0.6, {ease: FlxEase.expoInOut});
			if (selectedIndex + 1 < listOfButtons.length)
			{
				listOfButtons[selectedIndex].unHighlight();
				listOfButtons[selectedIndex + 1].highlight();
				selectedIndex++;
				trace('selected ' + selectedIndex);
			}
			else
			{
				listOfButtons[selectedIndex].unHighlight();
				selectedIndex = 0;
				listOfButtons[selectedIndex].highlight();
				trace('selected ' + selectedIndex);
			}
		}
		if (FlxG.keys.justPressed.LEFT)
		{
			lastInput = true;
			if (show == 'sus' && !killed && hand.alpha == 1)
				FlxTween.tween(hand, {alpha: 0, x: shower.x + 60, y: shower.y + 60}, 0.6, {ease: FlxEase.expoInOut});
			if (selectedIndex > 0)
			{
				listOfButtons[selectedIndex].unHighlight();
				listOfButtons[selectedIndex - 1].highlight();
				selectedIndex--;
				trace('selected ' + selectedIndex);
			}
			else
			{
				listOfButtons[selectedIndex].unHighlight();
				listOfButtons[listOfButtons.length - 1].highlight();
				selectedIndex = listOfButtons.length - 1;
				trace('selected ' + selectedIndex);
			}
		}

		if (FlxG.keys.justPressed.ENTER && !selectedSmth)
		{
			lastInput = true;
			if (show == 'sus' && !killed)
			{
				doHand();
				return;
			}
			selectedSmth = true;
			if (listOfButtons[selectedIndex].pognt == 'clown')
				transIn = transOut = null;
			listOfButtons[selectedIndex].select();
		}

		#if debug
		if (FlxG.keys.justPressed.NINE)
		{
			lastInput = true;
			FlxG.switchState(new WarningSubState());
		}
		#end
	}

	override function beatHit()
	{
		if (curBeat % 2 == 0 && show == 'bf')
			shower.animation.play('idle');

		super.beatHit();
	}
}
