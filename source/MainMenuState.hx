package;

import haxe.Timer;
import sys.thread.Thread;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.sound.FlxSound;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public var slider:FlxBackdrop;

	public static var killed:Bool = false;
	public static var show:String = "bf";

	public var showerlayer:FlxGroup;
	public var loadedshower:Bool = false;

	public static var playingshowermusic:Bool = false;

	var hand:DitherSprite;
	var handtrail:HazardTrail;
	var shower:FlxSprite;

	public static var trans:FlxSprite;

	var clownButton:TrickyButton;

	public var listOfButtons:Array<TrickyButton>;
	public var lastInput:Bool = true;

	var tinyMan:FlxSprite;
	var tinyManHit:FlxSprite;
	var text:FlxText = new FlxText(0, 0, '');
	var textTween:FlxTween;

	var chromaticabberation:Shaders.ChromaticAberrationEffect;

	var lines:Array<String> = [];

	private var isLoading:Bool = false;
	private var loadingThread:Thread;
	private var revealMask:FlxSprite;
	private var shaderTime:Float = 0;
	private var colorTransitionShader:Shaders.ColorTransitionShader;
	private var revealParticles:FlxTypedGroup<FlxSprite>;

	private static inline final TINY_MAN_SCALE = 0.66;
	private static inline final SHOWER_BASE_SCALE = 0.76;

	override function create()
	{
		listOfButtons = [
			new TrickyButton(765, 160, 'menu/Clown Mode Button', 'menu/Clown Mode Button CONFIRM', playStory, 'clown', 0, -40),
			new TrickyButton(975, 165, 'menu/FreePlayButton', 'menu/FreePlayButton CONFIRM', goToFreeplay, "free", 0, -40),
			new TrickyButton(975, 460, 'menu/OPTIONS Button', 'menu/OPTIONS Button CONFIRM', goToOptions, "options", 0, 45)
		];

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

		if (!FlxG.save.data.lowend)
		{
			var mist = new VolumetricCloudSprite(0, 0);
			mist.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
			mist.cloudType = MIST;
			mist.setColors(0xFF545FC4, 0xFFCACAFA);
			mist.blend = ADD;
			add(mist);
		}

		var hedgeBG:FlxSprite = new FlxSprite(-750, 110).loadGraphic(Paths.image('menu/HedgeBG', 'clown'));
		hedgeBG.setGraphicSize(Std.int(hedgeBG.width * 0.65));
		hedgeBG.antialiasing = !FlxG.save.data.lowend;
		add(hedgeBG);

		var foreground:FlxSprite = new FlxSprite(-750, 110).loadGraphic(Paths.image('menu/Transforeground', 'clown'));
		foreground.setGraphicSize(Std.int(foreground.width * 0.65));
		foreground.visible = !FlxG.save.data.lowend;
		add(foreground);

		chromaticabberation = new Shaders.ChromaticAberrationEffect();
		chromaticabberation.multiplier = 0.0002;
		if (!FlxG.save.data.lowend)
		{
			slider = new FlxBackdrop(Paths.image('menu/MenuSlider', 'clown'), FlxAxes.X);
			slider.velocity.set(-8, 0);
			slider.x = -20;
			slider.y = 209;
			slider.setGraphicSize(Std.int(slider.width * 0.65));
			add(slider);
			slider.shader = chromaticabberation.shader;
		}

		trace('im showin ' + show);

		if (FlxG.save.data.lowend)
			killed = true;

		shower = new FlxSprite(200, 280);

		if (!FlxG.save.data.lowend)
		{
			hand = new DitherSprite(0, 0);
			handtrail = new HazardTrail(hand, null);
			hand.visible = false;
			handtrail.visible = false;
		}

		Conductor.changeBPM(165);

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

		for (i in listOfButtons)
		{
			// just general compensation since pasc made this on 1920x1080 and we're on 1280x720
			i.spriteOne.setGraphicSize(Std.int(i.spriteOne.width * 0.7));
			i.spriteTwo.setGraphicSize(Std.int(i.spriteTwo.width * 0.7));
			add(i);
			add(i.spriteOne);
			add(i.spriteTwo);
		}

		revealParticles = new FlxTypedGroup<FlxSprite>();
		add(revealParticles);
		showerlayer = new FlxGroup();
		add(showerlayer);

		startAsyncLoading();

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

				tinyMan.setGraphicSize(Std.int(tinyMan.width * TINY_MAN_SCALE));

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
		{
			add(hand);
			add(handtrail);
		}

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

		#if debug
		FlxG.watch.add(this, "selectedIndex", "Selected Index");
		FlxG.watch.add(this, "loadedshower", "Loaded Shower");
		FlxG.watch.add(this, "isLoading", "Is Loading");
		FlxG.watch.add(this, "shower", "Shower");
		FlxG.watch.add(this, "loadingThread", "Loading Thread");
		FlxG.watch.add(this, "hand", "Hand");
		FlxG.watch.add(this, "tinyMan", "Tiny Man");
		FlxG.watch.add(this, "chromaticabberation", "Chromaticabberation");
		#end

		super.create();
	}

	private function startAsyncLoading()
	{
		if (isLoading)
			return;

		isLoading = true;

		if (!FlxG.save.data.lowend) // disable shower for lowend
			new FlxTimer().start(1, (_) -> // a lil delay for those people that have (a slower computer) brain damage
			{
				trace("Starting loading shower...");
				loadingThread = Thread.create(() ->
				{
					if (!loadedshower)
					{
						loadShower(show);

						if (loadedshower)
							onLoadComplete();
					}
				});
			});
	}

	private function onLoadComplete()
	{
		isLoading = false;

		if (shower != null && !FlxG.save.data.lowend)
		{
			trace("Starting shower...");
			var startX = shower.flipX ? shower.frameWidth : 0;
			var endX = shower.flipX ? 0 : shower.frameWidth;

			shower.clipRect = new flixel.math.FlxRect(startX, 0, 0, 0);

			colorTransitionShader = new Shaders.ColorTransitionShader();
			shower.shader = colorTransitionShader;

			// Animate horizontal reveal
			FlxTween.num(startX, endX, 1.2, {ease: FlxEase.quartOut}, function(w:Float)
			{
				if (shower.flipX)
				{
					shower.clipRect.x = w;
					shower.clipRect.width = shower.frameWidth - w;
				}
				else
				{
					shower.clipRect.width = w;
				}
				shower.clipRect = shower.clipRect;
			});

			// Animate vertical reveal
			FlxTween.num(0, shower.frameHeight, 0.8, {ease: FlxEase.quartOut}, function(h:Float)
			{
				shower.clipRect.height = h;
				shower.clipRect = shower.clipRect;
			});

			// Update shader time
			new FlxTimer().start(0.016, function(tmr:FlxTimer)
			{
				shaderTime += 0.016;
				colorTransitionShader.update(shaderTime);

				// Spawn reveal particles
				if (FlxG.random.bool(30))
				{
					var particle = new FlxSprite();
					particle.makeGraphic(4, 4, FlxColor.CYAN);

					// Calculate X based on reveal progress
					var progress = Math.min(shaderTime / 1.5, 1.0);
					var revealX = shower.x + (shower.frameWidth * progress);

					// Set Y within revealed area
					var revealHeight = shower.clipRect.height;
					particle.setPosition(revealX + FlxG.random.float(-2, 2), shower.y + FlxG.random.float(0, revealHeight));

					particle.alpha = 0.6;
					particle.velocity.x = FlxG.random.float(-20, 20);
					particle.velocity.y = FlxG.random.float(-50, 50);

					FlxTween.tween(particle, {alpha: 0}, 0.5, {
						onComplete: function(twn:FlxTween)
						{
							particle.kill();
							revealParticles.remove(particle);
						}
					});

					revealParticles.add(particle);
				}

				if (shaderTime >= 1.5)
				{
					shower.shader = null;
					tmr.cancel();
				}
				else
					tmr.reset(0.016);
			});
			trace("Shower loaded.");
		}
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
	}

	public function loadShower(who:String)
	{
		if (shower == null)
			return;

		switch (who)
		{
			case 'bf':
				shower.frames = Paths.getSparrowAtlas("menu/MenuBF/MenuBF", 'clown');
				shower.animation.addByPrefix('idle', 'BF idle menu', 24, false);
				shower.flipX = true;

				shower.setGraphicSize(Std.int(shower.width * SHOWER_BASE_SCALE));
				shower.x -= 150;

			case 'tricky':
				shower.frames = Paths.getSparrowAtlas("menu/MenuTricky/MenuTricky", 'clown');
				shower.animation.addByPrefix('idle', 'Tricky Idle menu instance');
				shower.y -= 155;
				shower.x -= 100;

				shower.setGraphicSize(Std.int(shower.width * SHOWER_BASE_SCALE));

				shower.shader = chromaticabberation.shader;
			case 'sus':
				shower.frames = Paths.getSparrowAtlas("menu/Sus/Menu_ALLSUS", 'clown');
				shower.animation.addByPrefix('idle', 'AmongUsIDLE', 24);
				shower.animation.addByPrefix('death', 'AMONG DEATH', 24, false);
				shower.animation.addByIndices('deathPost', 'AMONG DEATH', [5], "", 24, false);
				shower.animation.addByPrefix('no', 'AmongUs NuhUh', 24, false);

				shower.setGraphicSize(Std.int(shower.width * SHOWER_BASE_SCALE));

				shower.y += 35;
				shower.x += 20;

				if (hand != null)
				{
					hand.alpha = 0;
					hand.antialiasing = !FlxG.save.data.lowend;
					handtrail = new HazardTrail(hand, Paths.image('menu/Sus/AmongHandTrail', 'clown'));
					handtrail.copyParentShader = true;
					handtrail.antialiasing = !FlxG.save.data.lowend;
					handtrail.detail = 16;
					handtrail.fadeMultiplier = 0.3;
				}

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
				shower.setGraphicSize(Std.int(shower.width * SHOWER_BASE_SCALE));

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
		loadedshower = true;
		showerlayer.add(shower);

		shower.antialiasing = !FlxG.save.data.lowend;
		shower.visible = !FlxG.save.data.lowend;

		if (show == 'sus' && killed && !FlxG.save.data.lowend)
		{
			shower.offset.set(5, 10);
			shower.animation.play('deathPost');
		}
		else if (show != 'bf' && !FlxG.save.data.lowend)
			shower.animation.play('idle');
	}

	public function goToFreeplay()
	{
		FlxG.switchState(new FreeplayState());
		dispatchScriptEvent("onGoToFreeplay");
	}

	public function goToOptions()
	{
		FlxG.mouse.visible = false;
		FlxG.switchState(new OptionsMenu());
		dispatchScriptEvent("onGoToOptions");
	}

	public function playStory()
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
		dispatchScriptEvent("onPlayStory");
	}

	var selectedSmth = false;

	public static var selectedIndex = 0;

	function navigateButtons(newIndex:Int)
	{
		if (selectedIndex != newIndex)
		{
			if (show == 'sus' && !killed && hand.alpha == 1 && loadedshower)
				FlxTween.tween(hand, {alpha: 0, x: shower.x + 60, y: shower.y + 60}, 0.6, {ease: FlxEase.expoInOut});

			listOfButtons[selectedIndex].unHighlight();
			selectedIndex = newIndex;
			listOfButtons[selectedIndex].highlight();
		}
	}

	function doHand()
	{
		if (shower == null || hand == null || !loadedshower)
			return;

		shower.animation.play('no');
		var selected = listOfButtons[selectedIndex].spriteTwo;

		FlxTween.cancelTweensOf(hand);

		if (hand.alpha == 0)
		{
			hand.x = shower.x + 75;
			hand.y = shower.y + 50;
		}

		FlxTween.tween(hand, {
			alpha: 1,
			x: selected.x + 10,
			y: selected.y - 10
		}, 0.6, {ease: FlxEase.expoInOut});
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

		if (!selectedSmth)
		{
			for (i in 0...listOfButtons.length)
			{
				var mouseOver = FlxG.mouse.overlaps(listOfButtons[i].spriteOne) || FlxG.mouse.overlaps(listOfButtons[i].spriteTwo);

				if (mouseOver)
				{
					navigateButtons(i);
					if (FlxG.mouse.justPressed)
					{
						if (show == 'sus' && !killed)
						{
							doHand();
							return;
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
							lastInput = true;
							break;
						}
					}
				}

				if ((controls.ACCEPT)
					&& selectedIndex == i
					|| controls.RIGHT_P
					&& i == (selectedIndex + 1) % listOfButtons.length - 1
						|| controls.LEFT_P
						&& i == (selectedIndex + listOfButtons.length - 1) % listOfButtons.length - 1)
				{
					navigateButtons(i);

					if (controls.ACCEPT)
					{
						if (show == 'sus' && !killed)
						{
							doHand();
							return;
						}

						if (listOfButtons[selectedIndex].pognt == 'clown')
							transIn = transOut = null;
						selectedSmth = true;
						listOfButtons[selectedIndex].select();
						lastInput = true;
						break;
					}
				}
			}

			if (show == 'sus' && !killed && FlxG.mouse.overlaps(shower) && loadedshower)
			{
				if (FlxG.mouse.pressed)
				{
					killed = true;
					shower.animation.play('death');
					FlxG.sound.play(Paths.sound('AmongUs-Kill', 'clown'));

					FlxTween.cancelTweensOf(hand);
					FlxTween.tween(hand, {alpha: 0}, 0.4);

					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						shower.offset.set(5, 10);
						shower.animation.play('deathPost');
					});
				}
			}
		}

		if (FlxG.keys.justPressed.EIGHT)
		{
			lastInput = true;
			FlxG.switchState(new Test3DState());
		}
		if (FlxG.keys.justPressed.NINE)
		{
			lastInput = true;
			FlxG.switchState(new WarningSubState());
		}
		if (FlxG.keys.justPressed.ZERO)
		{
			lastInput = true;
			FlxG.switchState(new BlendModeState());
		}
		if (FlxG.keys.pressed.CONTROL)
		{
			if (FlxG.keys.justPressed.M) // Mod tester
				FlxG.switchState(new ModTestState());
			if (FlxG.keys.justPressed.C) // Config tester
				FlxG.switchState(new ConfigTester());
			if (FlxG.keys.justPressed.R)
			{ // Reload mods
				Main.reloadMods();
				FlxG.resetState();
			}
		}
	}

	override function beatHit()
	{
		if (curBeat % 2 == 0 && show == 'bf' && loadedshower)
			shower.animation.play('idle');

		super.beatHit();
	}
}
