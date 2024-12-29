package;

import openfl.Lib;
import openfl.filters.BlurFilter;
import openfl.filters.BitmapFilterQuality;
import openfl.geom.Point;
import flixel.group.FlxGroup;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import openfl.filters.ShaderFilter;
import WiggleEffect.WiggleEffectType;
import Shaders;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_Y:Float;

	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	public static var staticVar:PlayState;
	public static var beatTime:Float = 0;

	var forcedadcam:Bool = false;

	private var vocals:FlxSound;

	// tricky lines
	public var TrickyLinesSing:Array<String> = [];
	public var ExTrickyLinesSing:Array<String> = [];
	public var TrickyLinesMiss:Array<String> = [];

	// cutscene text unhardcoding
	public var cutsceneText:Array<String> = [];

	public var opp:Character;
	public var gf:Character; // public
	public var bf:Boyfriend; // public n' shit
	public var deadbf:Boyfriend = null;

	var MAINLIGHT:FlxSprite;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	var tstatic:FlxSprite;
	var tstaticSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound("staticSound", "preload"));

	var bg:FlxSprite;
	var stageFrontNevada:FlxSprite;
	var behindCharacters:LuisSprite;

	var hole:FlxSprite;
	var daBackground:NormalMapSprite;
	var cover:NormalMapSprite;
	var converHole:FlxSprite;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	var strumLineNotes:FlxTypedGroup<FlxSprite>; // made all this shit public, fuck// unfuck
	var playerStrums:FlxTypedGroup<FlxSprite>;
	var cpuStrums:FlxTypedGroup<FlxSprite>;

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private final maxhealth:Float = 2;
	private final minhealth:Float = 0;
	private var combo:Int = 0;
	private final comboThreshold:Int = 10;

	public static var misses:Int = 0;
	public static var comboBreaks:Int = 0;

	private var accuracy:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;

	private var healthBar:FlxBar;
	private var healthBarBG:FlxBar;

	public var generatedMusic:Bool = false;

	private var startingSong:Bool = false;

	public var iconP1:HealthIcon; // public now
	public var iconP2:HealthIcon;

	public var dadsinging:Bool = false;
	public var bfsinging:Bool = false;

	public var camHUD:FlxCamera;
	public var camEffect:FlxCamera;
	public var camOther:FlxCamera;

	var notesHitArray:Array<Date> = [];
	private var camGame:FlxCamera;

	var songScore:Int = 0;
	var scoreTxt:FlxText;
	var judgementCounter:FlxText;
	var scoreTxtTween:FlxTween;

	var gfDance:Bool = false;

	public static var campaignScore:Int = 0;
	public static var deathCounter:Int = 0;

	var ignoreDefaultZoom:Bool = false;
	var defaultCamZoom:Float = 1.05;
	var theZoom:Float = 1.05;

	public static final daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	public static var trans:FlxSprite;

	public final NoteOffset:Int = 40;

	var burningnotealpha:Float = 1; // i'm lazy fuck you -Luis
	var burningSoundEffect:FlxSound;
	var haloSoundEffect:FlxSound;

	public var hardermode:Bool = false;

	public var gammaCorrection:GammaCorrectionEffect = null;
	public var distortion:TextureDistortionEffect = null;
	public var blur:VignetteBlurEffect = null;
	public var mosaic:MosaicEffect = null;
	public var susWiggleEffect:WiggleEffect = null;
	public var wobble(default, set):Float = 5;

	public function set_wobble(value:Float):Float
	{
		wobble = value;
		susWiggleEffect.waveAmplitude = wobble / FlxG.width;

		return value;
	}

	public var colorSwap:ColorSwap = null;
	public final upsideOffset:Float = 120 / 360;
	public final ogOffset:Float = 180 / 360;

	var laneunderlay:FlxSprite = new FlxSprite(0, 0).makeGraphic(128, FlxG.height, FlxColor.WHITE);
	var laneunderlayTween:FlxTween;

	public var funkyNotes:Bool = false; // i liked the effect, what are you going to do about it?
	public var hardNotes:Bool = false;

	public var songName:String = "";
	public var classic:Bool = false;

	override public function create()
	{
		KeyBinds.keyCheck();

		songName = SONG.song;
		classic = songName.toLowerCase().endsWith('-old') || songName.toLowerCase().endsWith('-upside');
		songName = CoolUtil.capitalize(CoolUtil.cutDownSuffix(songName).replace("-", " ").replace("_", " "));

		FlxG.sound.cache(Paths.inst(PlayState.SONG.song));
		FlxG.sound.cache(Paths.voices(PlayState.SONG.song));
		burningSoundEffect = FlxG.sound.load(Paths.sound('Beatstreets/burnSound', 'clown'));
		haloSoundEffect = FlxG.sound.load(Paths.sound('Beatstreets/anticipation', 'clown'));
		haloSoundEffect.onComplete = function()
		{
			health = minhealth;
			shouldBeDead = true;
			FlxG.sound.play(Paths.sound('Beatstreets/death', 'clown'));
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		transIn = null;

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;
		misses = 0;
		comboBreaks = 0;

		resetSpookyText = true;

		FlxG.cameras.reset(camGame = new FlxCamera());
		FlxG.cameras.add(camHUD = new FlxCamera());
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camEffect = new FlxCamera());
		camEffect.bgColor.alpha = 0;
		FlxG.cameras.add(camOther = new FlxCamera());
		camOther.bgColor.alpha = 0;
		FlxCamera.defaultCameras = [camGame];

		/*if (FlxG.save.data.downscroll)
			{
				for (cameras in [camHUD, camEffect, camOther])
					cameras.flashSprite.scaleY *= -1;
				for (sprites in members)
					if (sprites is FlxSprite)
						if (sprites.cameras.contains(camHUD) || sprites.cameras.contains(camEffect) || sprites.cameras.contains(camOther))
						{
							var sprites:FlxSprite = cast sprites;
							sprites.flipY = !sprites.flipY;
						}
		}*/ // something crazy happend, i want to make a modchart :[ -Luis

		pixels(FlxG.save.data.lowend);

		gammaCorrection = new GammaCorrectionEffect();
		mosaic = new MosaicEffect();
		distortion = new TextureDistortionEffect();
		blur = new VignetteBlurEffect();
		camGame.filters = [new ShaderFilter(distortion.shader), new ShaderFilter(blur.shader)];

		colorSwap = new ColorSwap();
		if (SONG.stage.endsWith('-upside'))
			colorSwap.hue = upsideOffset;

		staticVar = this;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// unhardcode tricky sing strings lmao
		TrickyLinesSing = CoolUtil.coolTextFile(Paths.txt('trickyLinesSing', 'clown'));
		TrickyLinesMiss = CoolUtil.coolTextFile(Paths.txt('trickyLinesMiss', 'clown'));
		ExTrickyLinesSing = CoolUtil.coolTextFile(Paths.txt('exTrickyLinesSing', 'clown'));
		cutsceneText = CoolUtil.coolTextFile(Paths.txt('cutsceneText', 'clown'));

		switch (SONG.song.toLowerCase())
		{
			// case 'improbable-outset':
			// case 'madness':
			case 'hellclown':
				hardNotes = true;
			case 'expurgation':
				hardNotes = true;
		}

		trace('the stage is: ' + SONG.stage);
		trace('the song is: ' + SONG.song + ' with the story difficulty of: ' + storyDifficulty);

		tstatic = new FlxSprite(0, 0);
		tstatic.loadGraphic(Paths.image(SONG.stage.endsWith('-old')
			|| SONG.stage.endsWith('-upside') ? 'TrickyStatic-old' : 'TrickyStatic', 'clown'), true,
			320, 180);
		tstatic.antialiasing = !FlxG.save.data.lowend;
		tstatic.scrollFactor.set(0, 0);
		tstatic.screenCenter();
		tstatic.animation.add('static', [0, 1, 2], 24, true);
		tstatic.animation.play('static');
		tstatic.visible = !FlxG.save.data.lowend;
		tstatic.alpha = 0;
		tstatic.shader = colorSwap.shader;

		if (SONG.stage.startsWith('nevada'))
		{
			defaultCamZoom = 0.75;

			bg = new FlxSprite(-350, -300).loadGraphic(Paths.image(SONG.stage.endsWith('-upside') ? 'purple' : 'cyan', 'clown'));
			bg.antialiasing = !FlxG.save.data.lowend;
			bg.visible = !FlxG.save.data.lowend;
			bg.scrollFactor.set(0.9, 0.9);

			if (!SONG.stage.endsWith('spook'))
			{
				if (!FlxG.save.data.lowend)
				{
					var blurFilter = new BlurFilter(8, 8, BitmapFilterQuality.HIGH);
					var stageMoreBehind:FlxSprite = new FlxSprite(-1800, -390).loadGraphic(Paths.image('island_but_rocks_float', 'clown'));
					stageMoreBehind.setGraphicSize(Std.int(stageMoreBehind.width * 0.7));
					stageMoreBehind.scrollFactor.set(0.6, 0.6);
					stageMoreBehind.pixels.applyFilter(stageMoreBehind.pixels, stageMoreBehind.pixels.rect, new Point(), blurFilter);
					add(stageMoreBehind);

					var stageBehind:FlxSprite = new FlxSprite(-1200, -530).loadGraphic(Paths.image('island_but_rocks_float', 'clown'));
					stageBehind.scrollFactor.set(0.8, 0.8);
					stageMoreBehind.setGraphicSize(Std.int(stageMoreBehind.width * 0.8));
					stageBehind.pixels.applyFilter(stageBehind.pixels, stageBehind.pixels.rect, new Point(), blurFilter);
					add(stageBehind);
				}

				var island:String = SONG.stage.contains('-madness') ? 'island_but_rocks_float' : 'island_but_dumb';

				stageFrontNevada = new FlxSprite(-1100, -460).loadGraphic(Paths.image(island, 'clown'));
				stageFrontNevada.setGraphicSize(Std.int(stageFrontNevada.width * 1.4));
				stageFrontNevada.antialiasing = !FlxG.save.data.lowend;
				stageFrontNevada.scrollFactor.set(0.9, 0.9);
				// stageFrontNevada.shader = null;//idk, looks strange???
				// stageFrontNevada.angleX = 30;
				// stageFrontNevada.angleY = 65;
				stageFrontNevada.active = false;
				stageFrontNevada.moves = false;
				add(stageFrontNevada);

				MAINLIGHT = new FlxSprite(-470, -150).loadGraphic(Paths.image(SONG.stage.endsWith('-upside') ? 'hue-upside' : 'hue', 'clown'));
				MAINLIGHT.alpha - 0.3;
				MAINLIGHT.setGraphicSize(Std.int(MAINLIGHT.width * 0.9));
				MAINLIGHT.blend = SCREEN;
				MAINLIGHT.updateHitbox();
				MAINLIGHT.antialiasing = !FlxG.save.data.lowend;
				MAINLIGHT.visible = !FlxG.save.data.lowend;
				MAINLIGHT.scrollFactor.set(1.2, 1.2);
			}
			else
			{
				var auditorHellbg:FlxSprite = new FlxSprite(-1000, -1000).loadGraphic(Paths.image('fourth/bg', 'clown'));
				auditorHellbg.antialiasing = !FlxG.save.data.lowend;
				auditorHellbg.visible = !FlxG.save.data.lowend;
				auditorHellbg.scrollFactor.set(0.9, 0.9);
				auditorHellbg.setGraphicSize(Std.int(auditorHellbg.width * 5));
				auditorHellbg.active = false;
				auditorHellbg.moves = false;
				add(auditorHellbg);

				var stageFront:FlxSprite = new FlxSprite(-2000, -400).loadGraphic(Paths.image('hellclwn/island_but_red', 'clown'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 2.6));
				stageFront.antialiasing = !FlxG.save.data.lowend;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				stageFront.moves = false;
				add(stageFront);
			}
		}
		else
			switch (SONG.stage.toLowerCase())
			{
				case 'auditor-hell':
					defaultCamZoom = 0.55;

					var auditorHellbg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('fourth/bg', 'clown'));
					auditorHellbg.antialiasing = !FlxG.save.data.lowend;
					auditorHellbg.visible = !FlxG.save.data.lowend;
					auditorHellbg.scrollFactor.set(0.9, 0.9);
					auditorHellbg.setGraphicSize(Std.int(auditorHellbg.width * 4));
					auditorHellbg.active = false;
					add(auditorHellbg);

					if (SONG.player2 == 'exTricky')
					{
						hole = new FlxSprite(50, 530).loadGraphic(Paths.image('fourth/Spawnhole_Ground_BACK', 'clown'));
						hole.setGraphicSize(Std.int(hole.width * 1.55));
						hole.antialiasing = !FlxG.save.data.lowend;
						hole.scrollFactor.set(0.9, 0.9);

						cover = new NormalMapSprite(-180, 755, Paths.image('fourth/cover', 'clown'), Paths.image('fourth/cover_n', 'clown'));
						cover.angleX = cover.angleY = cover.lightMultiplier = 0;
						cover.antialiasing = !FlxG.save.data.lowend;
						cover.scrollFactor.set(0.9, 0.9);
						cover.setGraphicSize(Std.int(cover.width * 1.55));

						converHole = new FlxSprite(7, 578).loadGraphic(Paths.image('fourth/Spawnhole_Ground_COVER', 'clown'));
						converHole.antialiasing = !FlxG.save.data.lowend;
						converHole.visible = !FlxG.save.data.lowend;
						converHole.scrollFactor.set(0.9, 0.9);
						converHole.setGraphicSize(Std.int(converHole.width * 1.3));
					}

					var energyWall:FlxSprite = new FlxSprite(1350, -690).loadGraphic(Paths.image("fourth/Energywall", 'clown'));
					energyWall.antialiasing = !FlxG.save.data.lowend;
					energyWall.scrollFactor.set(0.9, 0.9);
					add(energyWall);

					daBackground = new NormalMapSprite(-350, -355, Paths.image('fourth/daBackground', 'clown'), Paths.image('fourth/daBackground_n', 'clown'));
					daBackground.lightMultiplier = 0.2;
					daBackground.normalMultiplier = 1.2;
					daBackground.angleX = 90;
					daBackground.angleY = 155;
					daBackground.antialiasing = !FlxG.save.data.lowend;
					daBackground.scrollFactor.set(0.9, 0.9);
					daBackground.setGraphicSize(Std.int(daBackground.width * 1.55));
					add(daBackground);
					if (SONG.player2 == 'exTricky')
						add(hole);
				default:
					defaultCamZoom = 0.9;
					var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
					bg.antialiasing = !FlxG.save.data.lowend;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					add(bg);

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stageFront.antialiasing = !FlxG.save.data.lowend;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					add(stageFront);
			}

		behindCharacters = new LuisSprite(0, 0);
		behindCharacters.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		behindCharacters.color = FlxColor.BLACK; // for shaders
		behindCharacters.alpha = 0;
		behindCharacters.scrollFactor.set();
		add(behindCharacters);

		gf = new Character(400, 130, SONG.gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		opp = new Character(100, 100, SONG.player2);

		if (opp.curCharacter == gf.curCharacter)
			gf.visible = false;

		bf = new Boyfriend(770, 450, SONG.player1);
		deadbf = new Boyfriend(0, 0, classic ? SONG.player1 : 'signDeath');
		deadbf.shader = classic ? null : new Shaders.NoAlphaShader();

		switch (opp.curCharacter)
		{
			case 'Tricky' | 'Tricky-old' | 'Tricky-upside':
				opp.x -= 40;
				gf.x += 50;
			case 'TrickyMask' | 'TrickyMask-old' | 'TrickyMask-upside':
				opp.y -= 20;
				opp.x -= 40;
				gf.x += 50;
			case 'TrickyH':
				opp.y -= 2000;
				opp.x -= 1400;
				gf.x -= 380;
			case 'exTricky':
				opp.x -= 250;
				opp.y -= 365;
				gf.x += 345;
				gf.y -= 25;
		}

		if (SONG.stage.startsWith('nevada'))
		{
			bf.x += 270;
			if (SONG.stage != 'nevada-spook')
				bf.x += 40;
		}
		else if (SONG.stage == 'auditor-hell')
		{
			bf.y -= 160;
			bf.x += 350;
			if (opp.curCharacter == 'exTricky')
				opp.visible = false;
		}

		if (gf.visible != false)
			gf.visible = !FlxG.save.data.lowend;
		add(gf);

		add(opp);

		if (SONG.stage == 'auditor-hell' && opp.curCharacter == 'exTricky')
		{
			cloneOne = new FlxSprite(0, 0);
			cloneTwo = new FlxSprite(0, 0);
			for (clones in [cloneOne, cloneTwo])
			{
				clones.frames = CachedFrames.fromSparrow('cln', 'fourth/Clone');
				clones.alpha = 0;
				clones.animation.addByPrefix('clone', 'Clone', 24, false);
				add(cloneOne);
			}

			add(cover);
			add(converHole);
			add(opp.exSpikes);
		}

		add(bf);

		if (opp.curCharacter == 'TrickyH')
		{
			gf.setGraphicSize(Std.int(gf.width * 0.8));
			bf.setGraphicSize(Std.int(bf.width * 0.8));
			gf.x += 220;
		}

		if (SONG.stage.startsWith('nevada') && !SONG.stage.endsWith('-spook'))
			add(MAINLIGHT);

		Conductor.songPosition = -5000;

		var strumLine:FlxSprite = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		STRUM_Y = strumLine.y;

		if (!FlxG.save.data.lowend)
		{
			susWiggleEffect = new WiggleEffect();
			susWiggleEffect.effectType = WiggleEffectType.DREAMY;
			susWiggleEffect.waveSpeed = 1;
			// Subtract 4 x note width phase shift cuz sine ain't 0 at strumLine for some reason??
			susWiggleEffect.shader.uTime.value = [(-STRUM_Y - Note.swagWidth * 0.5) / FlxG.height];
			if (!FlxG.save.data.downscroll)
				susWiggleEffect.shader.uTime.value = [(-STRUM_Y - Note.swagWidth * 10.3) / FlxG.height];

			susWiggleEffect.waveFrequency = Math.PI * 3;
			susWiggleEffect.waveAmplitude = wobble / FlxG.width;

			camEffect.filters = [new ShaderFilter(susWiggleEffect.shader)]; // by BopeeboRumbleMod.hx (the original file) -Luis
		}

		laneunderlay.visible = false;
		laneunderlay.cameras = [camHUD];
		laneunderlay.scrollFactor.set();
		add(laneunderlay);

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		cpuStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		generateSong(SONG.song);
		trace(SONG.song);
		trace(songName);

		camFollow = new FlxObject(0, 0, 1, 1);

		if (opp.curCharacter == 'TrickyH')
			camFollow.setPosition(opp.getMidpoint().x + 150, opp.getMidpoint().y + 265);
		else
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 8 / (cast(Lib.current.getChildAt(0), Main)).getFPSCap()); // kade, i curse you for this
		FlxG.camera.zoom = theZoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var dadcolor:FlxColor = FlxColor.fromRGB(opp.iconColor[0], opp.iconColor[1], opp.iconColor[2]);
		var bfcolor:FlxColor = FlxColor.fromRGB(bf.iconColor[0], bf.iconColor[1], bf.iconColor[2]);
		var dadinvertcolor:FlxColor = FlxColor.WHITE - dadcolor;
		var bfinvertcolor:FlxColor = FlxColor.WHITE - bfcolor;

		healthBarBG = new FlxBar(0, FlxG.height * 0.9, RIGHT_TO_LEFT, 600, 20, this, 'health', minhealth, maxhealth);
		if (FlxG.save.data.downscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.createFilledBar(dadinvertcolor, bfinvertcolor);
		healthBarBG.pixelPerfectRender = healthBarBG.pixelPerfectPosition = true;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', minhealth, maxhealth);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(dadcolor, bfcolor);
		healthBar.pixelPerfectRender = healthBar.pixelPerfectPosition = true;

		add(healthBarBG);
		add(healthBar);

		scoreTxt = new FlxText(0, 0, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.screenCenter();
		scoreTxt.borderSize = 1.25;
		scoreTxt.borderQuality = 2;
		scoreTxt.x -= 200;
		scoreTxt.y = healthBarBG.y + scoreTxt.height + 5;
		scoreTxt.alpha = 0;

		judgementCounter = new FlxText(20, 0, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.screenCenter(Y);
		add(judgementCounter);
		judgementCounter.alpha = 0;

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - 75;
		iconP2.pixelPerfectRender = iconP2.pixelPerfectPosition = true;
		add(iconP2);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - 75;
		iconP1.pixelPerfectRender = iconP1.pixelPerfectPosition = true;
		add(iconP1);

		add(scoreTxt);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		scoreTxt.cameras = [camOther];
		judgementCounter.cameras = [camOther];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];

		startingSong = true;

		if (SONG.stage == 'auditor-hell' || SONG.stage.startsWith('nevada'))
			add(tstatic);

		if (SONG.stage == 'auditor-hell')
			tstatic.alpha = 0.1;

		if (isStoryMode)
		{
			switch (SONG.song.toLowerCase())
			{
				case 'improbable-outset':
					camFollow.setPosition(bf.getMidpoint().x + 70, bf.getMidpoint().y - 50);
					if (playCutscene)
					{
						healthBar.alpha = 0;
						healthBarBG.alpha = 0;
						iconP1.alpha = 0;
						iconP2.alpha = 0;
						trickyCutscene();
						playCutscene = false;
					}
					else
						startCountdown();
				default:
					startCountdown();
			}
		}
		else
		{
			if (SONG.stage == 'auditor-hell' && opp.curCharacter == 'exTricky')
			{
				healthBar.alpha = 0;
				healthBarBG.alpha = 0;
				iconP1.alpha = 0;
				iconP2.alpha = 0;
				camFollow.setPosition(opp.getMidpoint().x + 150, opp.getMidpoint().y - 100);
				var spawnAnim = new FlxSprite(-150, -380);
				spawnAnim.frames = Paths.getSparrowAtlas('fourth/EXENTER', 'clown');
				spawnAnim.animation.addByPrefix('start', 'Entrance', 24, false);
				spawnAnim.animation.play('start');
				add(spawnAnim);

				var p = new FlxSound().loadEmbedded(Paths.sound("fourth/Trickyspawn", 'clown'));
				var pp = new FlxSound().loadEmbedded(Paths.sound("fourth/TrickyGlitch", 'clown'));
				p.play();
				spawnAnim.animation.finishCallback = function(pog:String)
				{
					pp.fadeOut();
					opp.visible = true;
					remove(spawnAnim);
					startCountdown();
				}
				new FlxTimer().start(0.001, function(tmr:FlxTimer)
				{
					if (spawnAnim.animation.frameIndex == 24)
					{
						pp.play();
					}
					else
						tmr.reset(0.001);
				});
			}
			else
				startCountdown();
		}

		// for (i in [bf, opp, gf, camHUD, camOther, camEffect,])
		// i.visible = false;
		// for doing the soundtracks images
		super.create();
	}

	function doStopSign(sign:Int = 0, fuck:Bool = false)
	{
		trace('sign ' + sign);
		var daSign:FlxSprite = new FlxSprite(0, 0);

		daSign.frames = CachedFrames.fromSparrow('sign', 'fourth/mech/Sign_Post_Mechanic');

		daSign.antialiasing = !FlxG.save.data.lowend;

		daSign.setGraphicSize(Std.int(daSign.width * 0.67));

		daSign.cameras = [camOther]; // so the notes have a own camera, but i need the sign a camera UPPER than the notes camera

		switch (sign)
		{
			case 0:
				daSign.animation.addByPrefix('sign', 'Signature Stop Sign 1', 24, false);
				daSign.x = FlxG.width - 650;
				daSign.angle = -90;
				daSign.y = -300;
			case 1:
				/*daSign.animation.addByPrefix('sign','Signature Stop Sign 2',20, false);
					daSign.x = FlxG.width - 670;
					daSign.angle = -90; */ // this one just doesn't work???
			case 2:
				daSign.animation.addByPrefix('sign', 'Signature Stop Sign 3', 24, false);
				daSign.x = FlxG.width - 780;
				daSign.angle = -90;
				if (FlxG.save.data.downscroll)
					daSign.y = -395;
				else
					daSign.y = -980;
			case 3:
				daSign.animation.addByPrefix('sign', 'Signature Stop Sign 4', 24, false);
				daSign.x = FlxG.width - 1070;
				daSign.angle = -90;
				daSign.y = -145;
		}
		add(daSign);
		daSign.flipX = fuck;
		daSign.animation.play('sign');
		daSign.animation.finishCallback = function(pog:String)
		{
			trace('ended sign');
			remove(daSign);
		}
	}

	var totalDamageTaken:Float = 0;

	var shouldBeDead:Bool = false;

	var interupt = false;

	// basic explanation of this is:
	// get the health to go to
	// tween the gremlin to the icon
	// play the grab animation and do some funny maths,
	// to figure out where to tween to.
	// lerp the health with the tween progress
	// if you loose any health, cancel the tween.
	// and fall off.
	// Once it finishes, fall off.

	function doGremlin(hpToTake:Int, duration:Int, persist:Bool = false)
		if (!grabbed)
		{
			interupt = false;
			grabbed = true;
			for (icons in [iconP1, iconP2, healthBar, healthBarBG])
				icons.color = FlxColor.GRAY;
			totalDamageTaken = 0;
			var gramlan:FlxSprite = new FlxSprite(0, 0);
			gramlan.frames = CachedFrames.fromSparrow('grem', 'fourth/mech/HP GREMLIN');
			gramlan.setGraphicSize(Std.int(gramlan.width * 0.76));
			gramlan.cameras = [camHUD];
			gramlan.x = iconP1.x + 120;
			gramlan.y = healthBarBG.y - 325;
			gramlan.animation.addByIndices('come', 'HP Gremlin ANIMATION', [0, 1], "", 24, false);
			gramlan.animation.addByIndices('grab', 'HP Gremlin ANIMATION', [
				2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24
			], "", 24, false);
			gramlan.animation.addByIndices('hold', 'HP Gremlin ANIMATION', [25, 26, 27, 28], "", 24);
			gramlan.animation.addByIndices('release', 'HP Gremlin ANIMATION', [29, 30, 31, 32, 33], "", 24, false);
			gramlan.antialiasing = !FlxG.save.data.lowend;
			// insert(members.indexOf(scoreTxt)-1, gramlan);
			add(gramlan);
			if (FlxG.save.data.downscroll)
			{
				gramlan.flipY = true;
				gramlan.y -= 150;
			}
			// over use of flxtween :)
			var startHealth = health;
			var toHealth = (hpToTake / 100) * startHealth; // simple math, convert it to a percentage then get the percentage of the health
			var perct = toHealth / maxhealth * 100;
			// trace('\nstart: $startHealth\nto: $toHealth\nwhich is prect: $perct');
			var onc:Bool = false;
			FlxG.sound.play(Paths.sound('fourth/GremlinWoosh', 'clown'));
			gramlan.animation.play('come');
			new FlxTimer().start(0.14, function(tmr:FlxTimer)
			{
				gramlan.animation.play('grab');
				FlxTween.tween(gramlan, {x: iconP1.x - 120}, 1, {
					ease: FlxEase.elasticIn,
					onComplete: function(tween:FlxTween)
					{
						trace('I got em');
						gramlan.animation.play('hold');
						FlxTween.tween(gramlan, {
							x: (healthBar.x + (healthBar.width * (FlxMath.remapToRange(perct, 0, 100, 100, 0) * 0.01) - 26)) - 75
						}, duration, {
							onUpdate: function(tween:FlxTween)
							{
								// lerp the health so it looks pog
								if (interupt && !onc && !persist)
								{
									onc = true;
									trace('oh shit');
									gramlan.animation.play('release');
									gramlan.animation.finishCallback = function(pog:String)
									{
										gramlan.alpha = 0;
									}
								}
								else if (!interupt || persist)
								{
									var pp = FlxMath.lerp(startHealth, toHealth, tween.percent);
									if (pp <= 0)
										pp = 0.1;
									health = pp;
								}

								if (shouldBeDead)
									health = minhealth;
							},
							onComplete: function(tween:FlxTween)
							{
								if (interupt && !persist)
								{
									remove(gramlan);
									grabbed = false;
									for (icons in [iconP1, iconP2, healthBar, healthBarBG])
										icons.color = FlxColor.WHITE;
								}
								else
								{
									trace('oh shit');
									gramlan.animation.play('release');
									if (persist && totalDamageTaken >= 0.7)
										health -= totalDamageTaken; // just a simple if you take a lot of damage wtih this, you'll loose probably.
									gramlan.animation.finishCallback = function(pog:String)
									{
										remove(gramlan);
									}
									grabbed = false;
									for (icons in [iconP1, iconP2, healthBar, healthBarBG])
										icons.color = FlxColor.WHITE;
								}
							}
						});
					}
				});
			});
		}
		else
			trace('already grabbed');

	var cloneOne:FlxSprite;
	var cloneTwo:FlxSprite;

	function doClone(side:Int)
	{
		var clone:FlxSprite = (side == 0) ? cloneOne : cloneTwo;
		if (clone.alpha == 1 || clone == null)
			return;

		clone.x = opp.x + (side == 0 ? -20 : 390);
		clone.y = opp.y + 140;
		clone.alpha = 1;

		clone.animation.play('clone');
		clone.animation.finishCallback = function(_:String)
		{
			clone.alpha = 0;
		};
	}

	var perfectMode:Bool = false;
	var bfScared:Bool = false;

	function trickySecondCutscene():Void // why is this a second method? idk cry about it loL!!!!
	{
		var done:Bool = false;

		trace('starting cutscene');

		var black:FlxSprite = new FlxSprite(-300, -120).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		black.scrollFactor.set();
		black.alpha = 0;

		var animation:FlxSprite = new FlxSprite(200, 300); // create the fuckin thing

		animation.frames = Paths.getSparrowAtlas('trickman', 'clown'); // add animation from sparrow
		animation.antialiasing = !FlxG.save.data.lowend;
		animation.animation.addByPrefix('cut1', 'Cutscene 1', 24, false);
		animation.animation.addByPrefix('cut2', 'Cutscene 2', 24, false);
		animation.animation.addByPrefix('cut3', 'Cutscene 3', 24, false);
		animation.animation.addByPrefix('cut4', 'Cutscene 4', 24, false);
		animation.animation.addByPrefix('pillar', 'Pillar Beam Tricky', 24, false);

		animation.setGraphicSize(Std.int(animation.width * 1.5));

		animation.alpha = 0;

		camFollow.setPosition(opp.getMidpoint().x + 300, bf.getMidpoint().y - 200);

		inCutscene = true;
		startedCountdown = false;
		generatedMusic = false;
		canPause = false;

		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		var sounders:FlxSound = new FlxSound().loadEmbedded(Paths.sound('honkers', 'clown'));
		var energy:FlxSound = new FlxSound().loadEmbedded(Paths.sound('energy shot', 'clown'));
		var roar:FlxSound = new FlxSound().loadEmbedded(Paths.sound('sound_clown_roar', 'clown'));
		var pillar:FlxSound = new FlxSound().loadEmbedded(Paths.sound('firepillar', 'clown'));

		var fade:FlxSprite = new FlxSprite(-300, -120).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(19, 0, 0));
		fade.scrollFactor.set();
		fade.alpha = 0;

		add(animation);

		add(black);

		add(fade);

		var startFading:Bool = false;
		var varNumbaTwo:Bool = false;
		var fadeDone:Bool = false;

		sounders.fadeIn(30);

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			if (fade.alpha != 1 && !varNumbaTwo)
			{
				camHUD.alpha -= 0.1;
				fade.alpha += 0.1;
				if (fade.alpha == 1)
				{
					// THIS IS WHERE WE LOAD SHIT UN-NOTICED
					varNumbaTwo = true;

					animation.alpha = 1;

					opp.alpha = 0;
				}
				tmr.reset(0.1);
			}
			else
			{
				fade.alpha -= 0.1;
				if (fade.alpha <= 0.5)
					fadeDone = true;
				tmr.reset(0.1);
			}
		});

		var roarPlayed:Bool = false;

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			if (!fadeDone)
				tmr.reset(0.1)
			else
			{
				if (animation.animation == null || animation.animation.name == null)
				{
					trace('playin cut cuz its funny lol!!!');
					animation.animation.play("cut1");
					resetSpookyText = false;
					createSpookyText(cutsceneText[1], 260, FlxG.height * 0.9);
				}

				if (!animation.animation.finished)
				{
					tmr.reset(0.1);
					trace(animation.animation.name + ' - FI ' + animation.animation.frameIndex);

					switch (animation.animation.frameIndex)
					{
						case 104:
							if (animation.animation.name == 'cut1')
								resetSpookyTextManual();
					}

					if (animation.animation.name == 'pillar')
					{
						if (animation.animation.frameIndex >= 85) // why is this not in the switch case above? idk cry about it
							startFading = true;
						camGame.shake(0.05);
					}
				}
				else
				{
					trace('completed ' + animation.animation.name);
					resetSpookyTextManual();
					if (tstatic.alpha != 0)
						manuallymanuallyresetspookytextmanual();
					switch (animation.animation.name)
					{
						case 'cut1':
							animation.animation.play('cut2');
						case 'cut2':
							animation.animation.play('cut3');
							energy.play();
						case 'cut3':
							animation.animation.play('cut4');
							resetSpookyText = false;
							createSpookyText(cutsceneText[2], 260, FlxG.height * 0.9);
							animation.x -= 100;
						case 'cut4':
							resetSpookyTextManual();
							sounders.fadeOut();
							pillar.fadeIn(4);
							animation.animation.play('pillar');
							animation.y -= 670;
							animation.x -= 100;
					}
					tmr.reset(0.1);
				}

				if (startFading)
				{
					sounders.fadeOut();
					trace('do the fade out and the text');
					if (black.alpha != 1)
					{
						tmr.reset(0.1);
						black.alpha += 0.02;

						if (black.alpha >= 0.7 && !roarPlayed)
						{
							roar.play();
							roarPlayed = true;
						}
					}
					else if (done)
					{
						endSong();
						camGame.stopFX();
					}
					else
					{
						done = true;
						tmr.reset(5);
					}
				}
			}
		});
	}

	public static var playCutscene:Bool = true;

	function trickyCutscene():Void // god this function is terrible
	{
		trace('starting cutscene');

		var playonce:Bool = false;

		trans = new FlxSprite(-400, -760);
		trans.frames = Paths.getSparrowAtlas('Jaws', 'clown');
		trans.antialiasing = !FlxG.save.data.lowend;

		trans.animation.addByPrefix("Close", "Jaws smol", 24, false);

		trans.setGraphicSize(Std.int(trans.width * 1.6));

		trans.scrollFactor.set();

		trace('added trancacscas ' + trans);

		var faded:Bool = false;
		var wat:Bool = false;
		var black:FlxSprite = new FlxSprite(-300, -120).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(19, 0, 0));
		black.scrollFactor.set();
		black.alpha = 0;
		var black3:FlxSprite = new FlxSprite(-300, -120).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(19, 0, 0));
		black3.scrollFactor.set();
		black3.alpha = 0;
		var red:FlxSprite = new FlxSprite(-300, -120).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.fromRGB(19, 0, 0));
		red.scrollFactor.set();
		red.alpha = 1;
		inCutscene = true;
		opp.alpha = 0;
		gf.alpha = 0;
		remove(bf);
		var nevada:FlxSprite = new FlxSprite(260, FlxG.height * 0.7);
		nevada.frames = Paths.getSparrowAtlas('somewhere', 'clown');
		nevada.antialiasing = !FlxG.save.data.lowend;
		nevada.animation.addByPrefix('nevada', 'somewhere idfk', 24, false);
		var animation:FlxSprite = new FlxSprite(-50, 200);
		animation.frames = Paths.getSparrowAtlas('intro', 'clown');
		animation.antialiasing = !FlxG.save.data.lowend;
		animation.animation.addByPrefix('fuckyou', 'Symbol', 24, false);
		animation.setGraphicSize(Std.int(animation.width * 1.2));
		nevada.setGraphicSize(Std.int(nevada.width * 0.5));
		add(animation); // add it to the scene

		// sounds

		var ground:FlxSound = new FlxSound().loadEmbedded(Paths.sound('ground', 'clown'));
		var wind:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wind', 'clown'));
		var cloth:FlxSound = new FlxSound().loadEmbedded(Paths.sound('cloth', 'clown'));
		var metal:FlxSound = new FlxSound().loadEmbedded(Paths.sound('metal', 'clown'));
		var buildUp:FlxSound = new FlxSound().loadEmbedded(Paths.sound('trickyIsTriggered', 'clown'));

		camHUD.visible = false;

		insert(members.indexOf(MAINLIGHT), bf);

		add(red);
		add(black);
		add(black3);

		add(nevada);

		add(trans);

		trans.animation.play("Close", false, false, 18);
		trans.animation.pause();

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			if (!wat)
			{
				tmr.reset(1.5);
				wat = true;
			}
			else
			{
				if (wat && trans.animation.frameIndex == 18)
				{
					trans.animation.resume();
					trace('playing animation...');
				}
				if (trans.animation.finished)
				{
					trace('animation done lol');
					new FlxTimer().start(0.01, function(tmr:FlxTimer)
					{
						if (bf.animation.finished && !bfScared)
							bf.animation.play('idle');
						else if (bf.animation.finished)
							bf.animation.play('scared');
						if (nevada.animation.curAnim == null)
						{
							trace('NEVADA | ' + nevada);
							nevada.animation.play('nevada');
						}
						if (!nevada.animation.finished && nevada.animation.curAnim.name == 'nevada')
						{
							if (nevada.animation.frameIndex >= 41 && red.alpha != 0)
							{
								trace(red.alpha);
								red.alpha -= 0.1;
							}
							if (nevada.animation.frameIndex == 34)
								wind.fadeIn();
							tmr.reset(0.1);
						}
						if (animation.animation.curAnim == null && red.alpha == 0)
						{
							remove(red);
							trace('play tricky');
							animation.animation.play('fuckyou', false, false, 40);
						}
						if (!animation.animation.finished && animation.animation.curAnim.name == 'fuckyou' && red.alpha == 0 && !faded)
						{
							trace("animation loop");
							tmr.reset(0.01);

							// animation code is bad I hate this
							// :(

							switch (animation.animation.frameIndex) // THESE ARE THE SOUNDS NOT THE ACTUAL CAMERA MOVEMENT!!!!
							{
								case 73:
									ground.play();
								case 84:
									metal.play();
								case 170:
									if (!playonce)
									{
										resetSpookyText = false;
										createSpookyText(cutsceneText[0], 260, FlxG.height * 0.9);
										playonce = true;
									}
									cloth.play();
								case 192:
									resetSpookyTextManual();
									if (tstatic.alpha != 0)
										manuallymanuallyresetspookytextmanual();
									buildUp.fadeIn();
								case 219:
									trace('reset thingy');
									buildUp.fadeOut();
							}

							// im sorry for making this code.
							// TODO: CLEAN THIS FUCKING UP (switch case it or smth)

							if (animation.animation.frameIndex == 190)
								bfScared = true;

							if (animation.animation.frameIndex >= 115 && animation.animation.frameIndex < 200)
							{
								camFollow.setPosition(opp.getMidpoint().x + 150, bf.getMidpoint().y + 50);
								if (camGame.zoom < 1.1)
									camGame.zoom += 0.01;
								else
									camGame.zoom = 1.1;
							}
							else if (animation.animation.frameIndex > 200 && camGame.zoom != defaultCamZoom)
							{
								camGame.shake(0.01, 3);
								if (camGame.zoom < defaultCamZoom || camFollow.y < bf.getMidpoint().y - 50)
								{
									camGame.zoom = defaultCamZoom;
									camFollow.y = bf.getMidpoint().y - 50;
								}
								else
								{
									camGame.zoom -= 0.008;
									camFollow.y = opp.getMidpoint().y -= 1;
								}
							}
							if (animation.animation.frameIndex >= 235)
								faded = true;
						}
						else if (red.alpha == 0 && faded)
						{
							trace('red gay');
							// animation finished, start a dialog or start the countdown (should also probably fade into this, aka black fade in when the animation gets done and black fade out. Or just make the last frame tranisiton into the idle animation)
							if (black.alpha != 1)
							{
								if (tstatic.alpha != 0)
									manuallymanuallyresetspookytextmanual();
								black.alpha += 0.4;
								tmr.reset(0.1);
								trace('increase blackness lmao!!!');
							}
							else
							{
								if (black.alpha == 1 && black.visible)
								{
									black.visible = false;
									black3.alpha = 1;
									trace('transision ' + black.visible + ' ' + black3.alpha);
									remove(animation);
									opp.alpha = 1;
									// why did I write this comment? I'm so confused
									// shitty layering but ninja muffin can suck my dick like mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
									remove(red);
									remove(black);
									remove(black3);
									opp.alpha = 1;
									gf.alpha = 1;
									add(black);
									add(black3);
									remove(tstatic);
									add(tstatic);
									tmr.reset(0.3);
									camGame.stopFX();
									camHUD.visible = true;
								}
								else if (black3.alpha != 0)
								{
									black3.alpha -= 0.1;
									tmr.reset(0.3);
									trace('decrease blackness lmao!!!');
								}
								else
								{
									wind.fadeOut();
									startCountdown();
								}
							}
						}
					});
				}
				else
				{
					trace(trans.animation.frameIndex);
					if (trans.animation.frameIndex == 30)
						trans.alpha = 0;
					tmr.reset(0.1);
				}
			}
		});
	}

	function startCountdown():Void
	{
		trace(beatTime = Conductor.crochet / 1000);
		inCutscene = false;

		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		showhud();
		new FlxTimer().start(beatTime, function(tmr:FlxTimer)
		{
			if (swagCounter < 4)
			{
				opp.dance();
				gf.dance();
				bf.dance();
			}
			else
				canPause = true;

			countdown(swagCounter);

			swagCounter += 1;
		}, 5);

		if (SONG.song.toLowerCase() == 'expurgation') // start the grem time
		{
			new FlxTimer().start(25, function(tmr:FlxTimer)
			{
				if (curStep < 2400)
				{
					if (canPause && !paused && health >= 1.5)
						doGremlin(40, 3);
					trace('checka ' + health);
					tmr.reset(25);
				}
			});
		}
	}

	public function countdown(counter:Int)
	{
		switch (counter)
		{
			case 0:
				FlxG.sound.play(Paths.sound('intro3', 'shared'), 0.6);
			case 1:
				var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ready', 'shared'));
				ready.cameras = [camHUD];
				ready.scrollFactor.set();
				ready.screenCenter();
				add(ready);
				FlxTween.tween(ready, {y: ready.y + 100, alpha: 0}, beatTime, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						ready.destroy();
					}
				});
				FlxG.sound.play(Paths.sound('intro2', 'shared'), 0.6);
			case 2:
				var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image('set', 'shared'));
				set.cameras = [camHUD];
				set.scrollFactor.set();
				set.screenCenter();
				add(set);
				FlxTween.tween(set, {y: set.y + 100, alpha: 0}, beatTime, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						set.destroy();
					}
				});
				FlxG.sound.play(Paths.sound('intro1', 'shared'), 0.6);
			case 3:
				var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image('go', 'shared'));
				go.cameras = [camHUD];
				go.scrollFactor.set();
				go.screenCenter();
				add(go);
				FlxTween.tween(go, {y: go.y + 100, alpha: 0}, beatTime, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn:FlxTween)
					{
						go.destroy();
					}
				});
				FlxG.sound.play(Paths.sound('introGo', 'shared'), 0.6);
			case 4:
		}
	}

	var grabbed:Bool = false;

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		trace('starting song :D');
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		if (SONG.song.toLowerCase() == 'madness' && isStoryMode)
			FlxG.sound.music.onComplete = trickySecondCutscene;
		else
			FlxG.sound.music.onComplete = endSong;
		vocals.play();

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			if (!paused)
				resyncVocals();
		});

		if (SONG.song.toLowerCase() == 'improbable-outset-upside')
			upsidezoom();
		zoomin();
	}

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();
		if (SONG.song.toLowerCase() == 'madness')
			vocals.volume = 0;

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		// i mean, it looped by the the sections of the song...
		for (section in noteData)
		{
			if (SONG.song.toLowerCase() == 'madness')
			{
				if (daBeats == 130)
					hardNotes = true;

				if (daBeats == 152)
					hardNotes = false;

				if (daBeats == 168)
					hardNotes = true;

				if (daBeats == 204)
					hardNotes = false;
			}

			if (SONG.song.toLowerCase() == 'expurgation')
			{
				if (daBeats == 118)
					hardNotes = false;
				if (daBeats == 134)
					hardNotes = true;
			}

			var playerNotes:Array<Int> = [0, 1, 2, 3, 8, 9, 10, 11];

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1]);

				var gottaHitNote:Bool = section.mustHitSection;

				if (!playerNotes.contains(songNotes[1]))
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note;

				if (gottaHitNote)
					swagNote = new Note(daStrumTime, daNoteData, songNotes[3], oldNote, false, true, hardNotes);
				else
					swagNote = new Note(daStrumTime, daNoteData, songNotes[3], oldNote);
				swagNote.shader = colorSwap.shader;

				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note;

					if (gottaHitNote)
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, songNotes[3], oldNote,
							true, true, hardNotes);
					else
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, songNotes[3], oldNote,
							true);
					sustainNote.shader = colorSwap.shader;

					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					sustainNote.x += NoteOffset;
					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				swagNote.x += NoteOffset;
				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function showhud()
	{
		for (hud in [healthBar, healthBarBG, iconP1, iconP2])
		{
			hud.alpha = 0;
			FlxTween.tween(hud, {alpha: 1}, beatTime * 4);
		}
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(NoteOffset, STRUM_Y);
			var atlasPath:String;

			if (player == 1 || FlxG.save.data.lowend)
				atlasPath = 'customnotes/Custom_static_arrows_Bf';
			else
				atlasPath = 'customnotes/Custom_static_arrows';

			babyArrow.frames = Paths.getSparrowAtlas(atlasPath, 'shared');

			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.antialiasing = !FlxG.save.data.lowend;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (SONG.song.toLowerCase() == 'improbable-outset' || SONG.song.toLowerCase() == 'madness')
				babyArrow.alpha = 0;
			else
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);
			babyArrow.shader = colorSwap.shader;

			strumLineNotes.add(babyArrow);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
				tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
				twn.active = false);
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished)
				tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished)
				twn.active = true);
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;

	var spookyText:FlxText;
	var spookyRendered:Bool = false;
	var spookySteps:Int = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!halfupdate)
		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
		}

		// scoreTxt.text = Ratings.CalculateRanking(songScore, accuracy);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState());
		}

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartingState());

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (halfupdate)
		{
			for (sprites in [tstatic, behindCharacters])
				if (sprites?.alpha != 0)
				{
					var newScaleX:Float = FlxG.width / sprites.frameWidth / camGame.zoom;
					var newScaleY:Float = FlxG.height / sprites.frameHeight / camGame.zoom;
					sprites.scale.set(newScaleX, newScaleY);
				}

			if (iconP1.scale.x != 1)
			{
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.max(0, Math.min(1, 1 - (curelapsed * 9))));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();
			}

			if (iconP2.scale.x != 1)
			{
				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.max(0, Math.min(1, 1 - (curelapsed * 9))));
				iconP2.scale.set(mult, mult);
				iconP2.updateHitbox();
			}

			var iconOffset:Int = 26;
			if (iconP1.visible && iconP1.alpha != 0)
				iconP1.x = healthBar.x
					+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
					+ (150 * iconP1.scale.x - 150) / 2
					- iconOffset;
			if (iconP2.visible && iconP2.alpha != 0)
				iconP2.x = healthBar.x
					+ (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01))
					- (150 * iconP2.scale.x) / 2
					- iconOffset * 2;
		}

		if (FlxG.keys.justPressed.EIGHT)
		{
			if (FlxG.keys.pressed.SHIFT)
				FlxG.switchState(new AnimationDebug(SONG.player1));
			else if (FlxG.keys.pressed.CONTROL)
				FlxG.switchState(new AnimationDebug(gf.curCharacter));
			else if (FlxG.keys.pressed.ALT)
				FlxG.switchState(new AnimationDebug('signDeath'));
			else
				FlxG.switchState(new AnimationDebug(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}
		}

		if (halfupdate)
		{
			if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
			{
				var singOffsetX:Float = 0;
				var singOffsetY:Float = 0;
				var camFollowX:Float = 0;
				var camFollowY:Float = 0;

				if (PlayState.SONG.notes[Std.int(curStep / 16)].gfSection)
				{
					camFollowX = gf.getMidpoint().x + 50;
					camFollowY = gf.getMidpoint().y + 50;
				}
				else if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection || forcedadcam)
				{
					switch (opp.curCharacter)
					{
						case 'TrickyH':
							defaultCamZoom = 0.35;
							camFollowX = opp.getMidpoint().x + 100;
							camFollowY = opp.getMidpoint().y + 300;
						case 'exTricky':
							camFollowX = opp.getMidpoint().x + 150;
							camFollowY = opp.getMidpoint().y - 150;
						default:
							if (opp.curCharacter.endsWith('-upside') && opp.animation.curAnim.name.startsWith('sing'))
							{
								switch (opp.animation.curAnim.name)
								{
									case 'singLEFT':
										singOffsetX = -20;
									case 'singDOWN':
										singOffsetY = 20;
									case 'singUP':
										singOffsetY = -20;
									case 'singRIGHT':
										singOffsetX = 20;
								}

								if (opp.animation.curAnim.curFrame <= 2)
								{
									singOffsetX *= 1.1;
									singOffsetY *= 1.1;
								}
							}
							camFollowX = opp.getMidpoint().x + 150 + singOffsetX;
							camFollowY = opp.getMidpoint().y + 25 + singOffsetY;
					}
				}
				else
				{
					if (opp.curCharacter == 'TrickyH')
						defaultCamZoom = theZoom;
					if (bf.curCharacter.endsWith('-upside') && bf.animation.curAnim.name.startsWith('sing'))
					{
						switch (bf.animation.curAnim.name)
						{
							case 'singLEFT':
								singOffsetX = -20;
							case 'singDOWN':
								singOffsetY = 20;
							case 'singUP':
								singOffsetY = -20;
							case 'singRIGHT':
								singOffsetX = 20;
						}
						if (bf.animation.curAnim.curFrame <= 2)
						{
							singOffsetX *= 1.1;
							singOffsetY *= 1.1;
						}
					}

					camFollowX = bf.getMidpoint().x - 100 + singOffsetX;
					camFollowY = bf.getMidpoint().y - 100 + singOffsetY;
				}
				camFollow.setPosition(camFollowX, camFollowY);
			}
		}

		if (!ignoreDefaultZoom)
			camGame.zoom = FlxMath.lerp(defaultCamZoom, camGame.zoom, Math.exp(-elapsed * 3.125));
		if (mosaic.pixelSize > 0)
			mosaic.updateShaderResolution(camGame.zoom);

		camEffect.zoom = camOther.zoom = camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125));

		if (health <= minhealth)
		{
			bf.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();
			FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();

			for (cameras in FlxG.cameras.list)
				cameras.filters = null;
			Main.fpsCounter.visible = false;
			Main.debug.visible = false;
			deadbf.x = bf.x;
			deadbf.y = bf.y;
			openSubState(new GameOverSubstate());
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				if (dunceNote.burning)
					dunceNote.cameras = [camHUD];
				else if (!dunceNote.isSustainNote && !funkyNotes)
					dunceNote.cameras = [camOther];
				else
					dunceNote.cameras = [camEffect];
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		// this is where I overuse FlxG.Random :)

		if (halfupdate)
			if (spookyRendered) // move shit around all spooky like
			{
				spookyText.angle = FlxG.random.int(-5, 5); // change its angle between -5 and 5 so it starts shaking violently.
				if (tstatic.alpha >= 0.1)
					tstatic.alpha = FlxG.random.float(0.1, 0.5); // change le alpha too :)
			}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (daNote.burning)
					daNote.alpha = burningnotealpha; // hmm theres a better way i guess

				if (!daNote.mustPress && (daNote.wasGoodHit && (!daNote.burning || (daNote.burning && SONG.haloNotes))))
					oppNoteHit(daNote);

				if (FlxG.save.data.downscroll)
					daNote.y = (STRUM_Y
						- (Conductor.songPosition - daNote.strumTime) * (-0.45 * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
							2)));
				else
					daNote.y = (STRUM_Y
						- (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
							2)));

				daNote.y -= (daNote.burning ? ((SONG.haloNotes && FlxG.save.data.downscroll) ? 185 : 65) : 0);

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (STRUM_Y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if (daNote.y < -daNote.height && !FlxG.save.data.downscroll || daNote.y >= STRUM_Y + 106 && FlxG.save.data.downscroll)
				{
					if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
					else
					{
						if (!daNote.burning && daNote.mustPress)
						{
							if (!daNote.isSustainNote || SONG.stage != 'nevedaSpook')
							{
								health -= 0.075;
								totalDamageTaken += 0.075;
								interupt = true;
								noteMiss(daNote.noteData, daNote.isSustainNote);
							}
							else if (daNote.isSustainNote && SONG.stage == 'nevedaSpook')
							{
								health -= 0.025;
								totalDamageTaken += 0.025;
								interupt = true;
							}
							vocals.volume = 0;
						}
					}
					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!halfupdate)
			if (!FlxG.save.data.lowend)
			{
				cpuStrums.forEach(function(spr:FlxSprite)
				{
					if (spr.animation.finished)
					{
						spr.animation.play('static');
						spr.centerOffsets();
					}
				});
			}
		if (!inCutscene)
			keyShit();
	}

	function createSpookyText(text:String, x:Float = null, y:Float = null):Void
	{
		spookySteps = curStep;
		spookyRendered = true;
		tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('staticSound', 'clown'));
		spookyText = new FlxText((x == null ? FlxG.random.float(opp.x + 40, opp.x + 120) : x), (y == null ? FlxG.random.float(opp.y + 200, opp.y + 300) : y));
		spookyText.setFormat("Impact", 128, SONG.stage.endsWith('-upside') ? FlxColor.MAGENTA : FlxColor.BLUE);
		if (SONG.stage == 'nevada-spook')
		{
			spookyText.size = 200;
			spookyText.x += 250;
		}
		spookyText.bold = true;
		spookyText.text = text;
		spookyText.pixelPerfectPosition = spookyText.pixelPerfectRender = true;
		add(spookyText);
	}

	public function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		deathCounter = 0;
		#if !switch
		var song:String = CoolUtil.cutDownSuffix(SONG.song);
		Highscore.saveScore(song, songScore, storyDifficulty);
		#end

		if (isStoryMode)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;

			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				MainMenuState.reRoll();
				LoadingState.loadAndSwitchState(new MainMenuState());
				FlxG.save.data.beatenHard = true;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 1) // not that the other remixes will be on the story mode...
					difficulty = '-old';
				if (storyDifficulty == 2)
					difficulty = '-upside';

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else
		{
			if (song.toLowerCase() == "expurgation")
				FlxG.save.data.beatEx = true;
			MainMenuState.reRoll();
			FlxG.switchState(new MainMenuState());
		}
	}

	function toPlay()
	{
		FlxG.switchState(new PlayState());
	}

	function toMenu()
	{
		FlxG.switchState(new MainMenuState());
	}

	var endingSong:Bool = false;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
		vocals.volume = 1;

		var rating:FlxSprite = new FlxSprite();
		var score:Float = 350;

		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit += wife;

		var daRating = daNote.rating;

		var healthDrain:Float = 0;

		if (SONG.song.toLowerCase() == 'hellclown')
			healthDrain = 0.04;

		switch (daRating)
		{
			case 'shit':
				scoreTxt.borderColor = FlxColor.RED;
				score = -300;
				if (combo >= comboThreshold)
					comboBreaks++;
				combo = 0;
				misses++;
				health -= 0.06;
				totalDamageTaken += 0.06;
				interupt = true;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;
			case 'bad':
				scoreTxt.borderColor = FlxColor.GREEN;
				score = 0;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				scoreTxt.borderColor = FlxColor.GREEN;
				score = 200;
				goods++;
				if (health < maxhealth && !grabbed)
					if (!hardermode)
						health += 0.04;
					else
						health += 0.02;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
			case 'sick':
				scoreTxt.borderColor = FlxColor.BLACK;
				if (health < maxhealth && !grabbed)
					if (!hardermode)
						health += 0.1 - healthDrain;
					else
						health += 0.06 - healthDrain;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
		}

		if (daRating != 'shit')
		{
			songScore += Math.round(score);

			rating.loadGraphic(Paths.image(daRating, 'shared'));
			rating.screenCenter();
			rating.y -= 50;
			rating.x = (FlxG.width * 0.55) - 125;

			if (FlxG.save.data.changedHit)
			{
				rating.x = FlxG.save.data.changedHitX;
				rating.y = FlxG.save.data.changedHitY;
			}
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);

			add(rating);
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = !FlxG.save.data.lowend;
			rating.updateHitbox();

			rating.cameras = [camHUD];

			var seperatedScore:Array<Int> = [];

			var comboSplit:Array<String> = (combo + "").split('');

			if (comboSplit.length == 2)
				seperatedScore.push(0); // make sure theres a 0 in front or it looks weird lol!

			for (i in 0...comboSplit.length)
			{
				var str:String = comboSplit[i];
				seperatedScore.push(Std.parseInt(str));
			}

			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('num' + Std.int(i), 'preload'));
				numScore.screenCenter();
				numScore.x = rating.x + (43 * daLoop) - 50;
				numScore.y = rating.y + 100;
				numScore.cameras = [camHUD];

				numScore.antialiasing = !FlxG.save.data.lowend;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				if (combo >= comboThreshold)
					add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, beatTime, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}

			FlxTween.tween(rating, {alpha: 0}, beatTime, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});
		}
	}

	private function keyShit():Void // I've invested in emma stocks
	{
		var control = PlayerSettings.player1.controls;

		// control arrays, order L D R U
		var holdArray:Array<Bool> = [control.LEFT, control.DOWN, control.UP, control.RIGHT];
		var pressArray:Array<Bool> = [control.LEFT_P, control.DOWN_P, control.UP_P, control.RIGHT_P];
		var releaseArray:Array<Bool> = [control.LEFT_R, control.DOWN_R, control.UP_R, control.RIGHT_R];

		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData] && daNote.alpha != 0.1)
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && generatedMusic && !bf.stunned)
		{
			bf.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol

								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				if (!FlxG.save.data.ghost)
				{
					for (shit in 0...pressArray.length)
					{ // if a direction is hit that shouldn't be
						if (pressArray[shit] && !directionList.contains(shit))
							noteMiss(shit, possibleNotes[0].isSustainNote); // this may be problematic. //it is.
					}
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
					{
						scoreTxt.borderColor = FlxColor.BLACK; // this one is from the  kade engine 1.3
						if (coolNote.burning)
						{
							if (SONG.haloNotes)
							{
								bf.playAnim('singUPmiss', true);
								/*bf.stunned = true; //original idea for the halo note was supposed to be 2 hits to die, but after getting more than the maxHealth it will anulate the next death.
									if (health > (maxhealth / 1.5))
									{
										health -= maxhealth / 2;//thas alota of damage!
										totalDamageTaken += maxhealth / 2;
										interupt = true;
										laneUnderlay(playerStrums.members[coolNote.noteData], FlxColor.RED);
										new FlxTimer().start(0.3, function(tmr:FlxTimer)
										{
											bf.stunned = false;
											bf.dance();
										});
									}
									else */
								{
									// lol death
									camHUD.alpha = camOther.alpha = camEffect.alpha = 0;
									FlxTween.cancelTweensOf(camGame);
									inCutscene = true;
									generatedMusic = false;
									canPause = false;
									// persistentUpdate = false;
									// persistentDraw = false;
									paused = true;
									vocals.stop();
									vocals.volume = 0;
									FlxG.sound.music.stop();
									FlxG.sound.music.volume = 0;
									camFollow.setPosition(bf.getMidpoint().x - 100, bf.getMidpoint().y - 100);
									camGame.filters = [
										new ShaderFilter(gammaCorrection.shader),
										new ShaderFilter(distortion.shader),
										new ShaderFilter(blur.shader)
									];
									FlxTween.tween(behindCharacters, {alpha: 1}, 0.8);
									FlxTween.tween(gammaCorrection, {gamma: 1.5}, 0.8);
									defaultCamZoom = 0.9;
									haloSoundEffect.play(true);
								}
							}
							else
							{
								health -= 0.45;
								totalDamageTaken += 0.45;
								interupt = true;
								coolNote.wasGoodHit = true;
								coolNote.canBeHit = false;
								coolNote.kill();
								notes.remove(coolNote, true);
								coolNote.destroy();
								burningSoundEffect.play(true);
								playerStrums.forEach(function(spr:FlxSprite)
								{
									if (pressArray[spr.ID] && spr.ID == coolNote.noteData)
									{
										var smoke:FlxSprite = new FlxSprite(spr.x - spr.width + 15, spr.y - spr.height);
										smoke.frames = Paths.getSparrowAtlas('Smoke', 'clown');
										smoke.animation.addByPrefix('boom', 'smoke', 24, false);
										smoke.animation.play('boom');
										smoke.setGraphicSize(Std.int(smoke.width * 0.6));
										smoke.cameras = [camHUD];
										smoke.shader = colorSwap.shader;
										add(smoke);
										smoke.animation.finishCallback = function(name:String)
										{
											smoke.shader = null;
											smoke.kill();
										}
									}
								});
							}
						}
						else
							goodNoteHit(coolNote);
					}
				}
			}
			else if (!FlxG.save.data.ghost)
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit);
			}
		}

		if (bf.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true)))
			if (bf.animation.curAnim.name.startsWith('sing') && !bf.animation.curAnim.name.endsWith('miss'))
				bf.dance();

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm')
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function laneUnderlay(spr:FlxSprite, color:FlxColor):Void
	{
		CoolUtil.centerOnSprite(laneunderlay, spr, X);
		laneunderlay.screenCenter(Y);
		laneunderlay.color = color;
		laneunderlay.alpha = 0.5;
		laneunderlay.visible = true;

		if (laneunderlayTween != null)
			laneunderlayTween.cancel();

		laneunderlayTween = FlxTween.tween(laneunderlay, {alpha: 0}, beatTime, {
			onComplete: function(tween:FlxTween)
			{
				laneunderlay.visible = false;
				laneunderlayTween = null;
			}
		});
	}

	function noteMiss(direction:Int = 1, issus:Bool = false):Void
	{
		if (!bf.stunned)
		{
			if (!issus)
				laneUnderlay(playerStrums.members[direction], hardermode ? FlxColor.RED : SONG.stage.endsWith('-upside') ? FlxColor.MAGENTA : FlxColor.CYAN);

			scoreTxt.borderColor = FlxColor.RED;

			if (hardermode)
			{
				if (!issus)
				{
					var healthtaken:Float = 0;
					if (health > maxhealth * 0.75)
						healthtaken = maxhealth * 0.25;
					else if (health > maxhealth * 0.5)
						healthtaken = maxhealth * 0.2;
					else
						healthtaken = maxhealth * 0.1;
					health -= healthtaken;
					totalDamageTaken += healthtaken;
					FlxG.sound.play(Paths.sound('Death-noise', 'clown'));
				}
			}
			else
			{
				health -= 0.08;
				totalDamageTaken += 0.08;
			}

			interupt = true;
			if (combo >= comboThreshold)
				comboBreaks++;
			combo = 0;
			misses++;
			songScore -= 10;
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3, 'shared'), FlxG.random.float(0.1, 0.2));

			if (opp.curCharacter.toLowerCase().contains("Tricky")
				&& FlxG.random.bool(opp.curCharacter == "Tricky"
					|| opp.curCharacter == "Tricky-old"
					|| opp.curCharacter == "Tricky-upside" ? 10 : 4)
				&& !spookyRendered
				&& (SONG.stage.startsWith("nevada") && !SONG.stage.endsWith('-spook'))) // create spooky text :flushed:
				createSpookyText(TrickyLinesMiss[FlxG.random.int(0, TrickyLinesMiss.length)]);

			switch (direction)
			{
				case 0:
					bf.playAnim('singLEFTmiss', true);
				case 1:
					bf.playAnim('singDOWNmiss', true);
				case 2:
					bf.playAnim('singUPmiss', true);
				case 3:
					bf.playAnim('singRIGHTmiss', true);
			}
			updateAccuracy();
		}
	}

	function updateAccuracy()
	{
		totalPlayed += 1;
		accuracy = totalNotesHit / totalPlayed * 100;

		scoreTxt.text = Ratings.CalculateRanking(songScore, accuracy);
		judgementCounter.text = 'Sicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\n';
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (!bfsinging)
			iconBop(iconP1);
		bfsinging = true;

		if (hardermode && !note.isSustainNote)
		{
			bf.chromaticabberation.multiplier = 0.001;
			FlxTween.cancelTweensOf(bf.chromaticabberation);
			FlxTween.tween(bf.chromaticabberation, {multiplier: 0.0001}, 0.3);
		}

		if (!note.isSustainNote)
		{
			if (scoreTxtTween != null)
				scoreTxtTween.cancel();

			scoreTxt.scale.x = 1.2;
			scoreTxt.scale.y = 1.2;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, beatTime, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}

		if (scoreTxt.alpha == 0)
			FlxTween.tween(scoreTxt, {alpha: 1}, beatTime * 2);

		if (judgementCounter.alpha == 0)
			FlxTween.tween(judgementCounter, {alpha: 1}, beatTime * 2);

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}
			else
				totalNotesHit += 1;
			switch (note.noteData)
			{
				case 2:
					if (note.isSustainNote && bf.animation.curAnim.name == 'idle')
						bf.playAnim('singUP');
					else if (!note.isSustainNote)
						bf.playAnim('singUP', true);

				case 3:
					if (note.isSustainNote && bf.animation.curAnim.name == 'idle')
						bf.playAnim('singRIGHT');
					else if (!note.isSustainNote)
						bf.playAnim('singRIGHT', true);

				case 1:
					if (note.isSustainNote && bf.animation.curAnim.name == 'idle')
						bf.playAnim('singDOWN');
					else if (!note.isSustainNote)
						bf.playAnim('singDOWN', true);

				case 0:
					if (note.isSustainNote && bf.animation.curAnim.name == 'idle')
						bf.playAnim('singLEFT');
					else if (!note.isSustainNote)
						bf.playAnim('singLEFT', true);
			}
			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
					spr.animation.play('confirm', true);
			});
			note.wasGoodHit = true;
			vocals.volume = 1;
			note.kill();
			notes.remove(note, true);
			note.destroy();
			updateAccuracy();
		}
	}

	function oppNoteHit(note:Note):Void
	{
		if (SONG.song.toLowerCase() != 'expurgation' && !note.isSustainNote && !note.burning && health > 0.2)
			health -= hardermode ? 0.06 : 0.03;

		if (hardermode && !note.isSustainNote)
		{
			opp.chromaticabberation.multiplier = 0.001;
			FlxTween.cancelTweensOf(opp.chromaticabberation);
			FlxTween.tween(opp.chromaticabberation, {multiplier: 0.0001}, 0.3);
		}

		if (!dadsinging)
			iconBop(iconP2);
		dadsinging = true;

		var altAnim:String = "";

		if (SONG.notes[Math.floor(curStep / 16)] != null)
			if (SONG.notes[Math.floor(curStep / 16)].altAnim)
				altAnim = '-alt';

		if (!(curBeat >= 532 && curBeat <= 536 && SONG.song.toLowerCase() == "expurgation")) // oh my fucking god i hate this code
		{
			switch (Math.abs(note.noteData))
			{
				case 2:
					if (note.isSustainNote && opp.animation.curAnim.name == 'idle')
						opp.playAnim('singUP' + altAnim);
					else if (!note.isSustainNote)
						opp.playAnim('singUP' + altAnim, true);
				case 3:
					if (note.isSustainNote && opp.animation.curAnim.name == 'idle')
						opp.playAnim('singRIGHT' + altAnim);
					else if (!note.isSustainNote)
						opp.playAnim('singRIGHT' + altAnim, true);
				case 1:
					if (note.isSustainNote && opp.animation.curAnim.name == 'idle')
						opp.playAnim('singDOWN' + altAnim);
					else if (!note.isSustainNote)
						opp.playAnim('singDOWN' + altAnim, true);
				case 0:
					if (note.isSustainNote && opp.animation.curAnim.name == 'idle')
						opp.playAnim('singLEFT' + altAnim);
					else if (!note.isSustainNote)
						opp.playAnim('singLEFT' + altAnim, true);
			}
		}

		if (!FlxG.save.data.lowend)
		{
			cpuStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
					spr.animation.play('confirm', true);
				if (spr.animation.curAnim.name == 'confirm')
				{
					spr.centerOffsets();
					spr.offset.x -= 13;
					spr.offset.y -= 13;
				}
				else
					spr.centerOffsets();
			});

			switch (opp.curCharacter)
			{
				case 'TrickyMask' | 'TrickyMask-old' | 'TrickyMask-upside': // 1% to 2% chance
					if (FlxG.random.bool(2) && !spookyRendered && !note.isSustainNote)
						createSpookyText(TrickyLinesSing[FlxG.random.int(0, TrickyLinesSing.length)]);
				case 'Tricky' | 'Tricky-old' | 'Tricky-upside': // 20% chance
					if (FlxG.random.bool(20) && !spookyRendered && !note.isSustainNote)
						createSpookyText(TrickyLinesSing[FlxG.random.int(0, TrickyLinesSing.length)]);
				case 'TrickyH': // 45% chance
					if (FlxG.random.bool(45) && !spookyRendered && !note.isSustainNote)
						createSpookyText(TrickyLinesSing[FlxG.random.int(0, TrickyLinesSing.length)]);
					if (!SONG.notes[Math.floor(curStep / 16)].mustHitSection)
						camGame.shake(0.01, 0.2);
				case 'exTricky': // 60% chance
					if (FlxG.random.bool(60) && !spookyRendered && !note.isSustainNote)
						createSpookyText(ExTrickyLinesSing[FlxG.random.int(0, ExTrickyLinesSing.length)]);
			}
		}

		opp.holdTimer = 0;

		if (SONG.needsVoices)
			vocals.volume = 1;

		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	var resetSpookyText:Bool = true;

	function resetSpookyTextManual():Void
	{
		trace('reset spooky');
		spookySteps = curStep;
		spookyRendered = true;
		tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('staticSound', 'clown'));
		resetSpookyText = true;
	}

	function manuallymanuallyresetspookytextmanual()
	{
		remove(spookyText);
		spookyRendered = false;
		tstatic.alpha = 0;
	}

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();

		if (lastStepHit >= curStep)
			return;
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		// EX TRICKY HARD CODED EVENTS

		if (SONG.song.toLowerCase() == 'expurgation')
		{
			switch (curStep)
			{
				case 384:
					doStopSign(0);
				case 511:
					doStopSign(2);
					doStopSign(0);
				case 610:
					doStopSign(3);
				case 720:
					doStopSign(2);
				case 991:
					doStopSign(3);
				case 1184:
					doStopSign(2);
				case 1218:
					doStopSign(0);
				case 1235:
					doStopSign(0, true);
				case 1200:
					doStopSign(3);
				case 1328:
					doStopSign(0, true);
					doStopSign(2);
				case 1439:
					doStopSign(3, true);
				case 1567:
					doStopSign(0);
				case 1584:
					doStopSign(0, true);
				case 1600:
					doStopSign(2);
				case 1706:
					doStopSign(3);
				case 1917:
					doStopSign(0);
				case 1923:
					doStopSign(0, true);
				case 1927:
					doStopSign(0);
				case 1932:
					doStopSign(0, true);
				case 2032:
					doStopSign(2);
					doStopSign(0);
				case 2036:
					doStopSign(0, true);
				case 2162:
					doStopSign(2);
					doStopSign(3);
				case 2193:
					doStopSign(0);
				case 2202:
					doStopSign(0, true);
				case 2239:
					doStopSign(2, true);
				case 2258:
					doStopSign(0, true);
				case 2304:
					doStopSign(0, true);
					doStopSign(0);
				case 2326:
					doStopSign(0, true);
				case 2336:
					doStopSign(3);
				case 2447:
					doStopSign(2);
					doStopSign(0, true);
					doStopSign(0);
				case 2480:
					doStopSign(0, true);
					doStopSign(0);
				case 2512:
					doStopSign(2);
					doStopSign(0, true);
					doStopSign(0);
				case 2544:
					doStopSign(0, true);
					doStopSign(0);
				case 2575:
					doStopSign(2);
					doStopSign(0, true);
					doStopSign(0);
				case 2608:
					doStopSign(0, true);
					doStopSign(0);
				case 2604:
					doStopSign(0, true);
				case 2655:
					doGremlin(10, 6, true);
				case 2912:
					doGremlin(5, 7, true);
			}
		}

		if (SONG.song.toLowerCase() == 'madness')
			if ((curStep >= 2144 && curStep < 2159 && curStep % 2 == 0) || (curStep >= 2160 && curStep < 2168))
				zoomin();

		if (spookyRendered && spookySteps + 3 < curStep)
		{
			if (resetSpookyText)
			{
				remove(spookyText);
				spookyRendered = false;
			}
			tstatic.alpha = SONG.stage == 'auditor-hell' ? 0.1 : 0;
		}

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if (lastBeatHit >= curBeat)
			return;

		if (generatedMusic)
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				opp.dance();
		}

		if (curBeat % 2 == 0
			&& !opp.animation.curAnim.name.startsWith('sing')
			&& (opp.curCharacter == 'TrickyMask-old' || opp.curCharacter == 'TrickyMask-upside'))
			opp.dance(true);

		if (!bf.animation.curAnim.name.startsWith('sing') && !bf.animation.curAnim.name.startsWith('scared') && curBeat % 2 == 0)
			bf.dance(true);
		else if (healthBar.percent < 20 && bf.curCharacter == 'bf' && !bf.animation.curAnim.name.startsWith('sing'))
			bf.playAnim('scared', true);

		switch (SONG.song.toLowerCase())
		{
			case 'improbable-outset':
				if (curBeat % 2 == 0 && curBeat % 4 != 0 && (curBeat >= 64 && curBeat < 128 || curBeat >= 192 && curBeat < 256))
					zoomin();

				if (curBeat == 28)
					strumLineNotes.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {alpha: 1}, beatTime);
					});

				if (curBeat == 352)
					strumLineNotes.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {alpha: 0}, beatTime * 2);
					});
			case 'madness':
				if (curBeat % 4 != 0 && (curBeat >= 528 && curBeat < 538 || curBeat >= 544 && curBeat < 608 && curBeat % 2 == 0))
					zoomin();

				if (curBeat == 32)
					strumLineNotes.forEach(function(spr:FlxSprite)
					{
						FlxTween.tween(spr, {alpha: 1}, beatTime);
					});

				if (curBeat == 192)
					defaultCamZoom = 0.85;

				if (curBeat == 256)
					defaultCamZoom = 0.75;

				if (curBeat == 512)
				{
					healthBar.visible = false;
					healthBarBG.visible = false;
					strumLineNotes.visible = false;
					notes.visible = false;
					iconP1.visible = false;
					iconP2.visible = false;
					scoreTxt.visible = false;
					judgementCounter.visible = false;
					funkyNotes = true;
					hardNotes = true;
				}

				if (curBeat == 538)
				{
					strumLineNotes.visible = true;
					notes.visible = true;
					forcedadcam = true;
				}

				if (curBeat == 542)
				{
					healthBar.visible = true;
					healthBarBG.visible = true;
					iconP1.visible = true;
					iconP2.visible = true;
					scoreTxt.visible = true;
					judgementCounter.visible = true;
					forcedadcam = false;
				}

				if (curBeat == 672)
					madnesseffect();

				if (curBeat == 816)
				{
				}
			case 'expurgation':
				if (curBeat == 472)
				{
					camGame.flash(FlxColor.WHITE, beatTime * 2);
					daBackground.lightMultiplier = 0;
					pixels(true);
					mosaic.pixelSize = daPixelZoom;
					camGame.filters = [
						new ShaderFilter(distortion.shader),
						new ShaderFilter(blur.shader),
						new ShaderFilter(mosaic.shader)
					];
					camHUD.filters = [new ShaderFilter(mosaic.shader)];
					hardNotes = false;
				}

				if (curBeat == 532)
				{
					defaultCamZoom -= 0.1;
					FlxTween.tween(distortion, {multiplier: 1.4}, beatTime * 4);
					FlxTween.tween(blur, {multiplier: 0.2}, beatTime * 4);
				}

				if (curBeat == 536)
				{
					camGame.flash(FlxColor.BLUE, beatTime * 2);
					daBackground.lightMultiplier = 0.3;
					distortion.multiplier = 0.2;
					blur.multiplier = 1;
					defaultCamZoom = theZoom;
					pixels(FlxG.save.data.lowend);
					mosaic.pixelSize = 0;
					mosaic.updateShaderResolution(1);
					camGame.filters = [
						new ShaderFilter(gammaCorrection.shader),
						new ShaderFilter(distortion.shader),
						new ShaderFilter(blur.shader)
					];
					camHUD.filters = [];
					hardNotes = true;
					funkyNotes = true;
					FlxTween.tween(this, {wobble: 10}, beatTime * 2);
					FlxTween.tween(gammaCorrection, {gamma: 1.1}, beatTime * 2);
				}

				if (curBeat == 664)
				{
					FlxTween.tween(gammaCorrection, {gamma: 1}, beatTime);
					FlxTween.tween(daBackground, {lightMultiplier: 0.2}, beatTime);
				}

				if (curBeat == 728)
				{
					for (sprites in [cloneOne, cloneTwo, cover, converHole])
						if (sprites != null)
						{
							remove(sprites);
							insert(members.indexOf(behindCharacters), sprites);
						}
					FlxTween.tween(behindCharacters, {alpha: 0.8}, beatTime * 32, {
						onComplete: (tween:FlxTween) ->
						{
							behindCharacters.alpha = 1;
							if (tstatic != null)
							{
								remove(behindCharacters);
								insert(members.indexOf(tstatic), behindCharacters);
							}
						}
					});
					FlxTween.tween(daBackground, {lightMultiplier: -0.2}, beatTime * 32);
					FlxTween.tween(gammaCorrection, {gamma: 1.2}, beatTime * 32);
				}
			case 'improbable-outset-old':
				if (curBeat % 2 == 0 && curBeat % 4 != 0 && (curBeat >= 64 && curBeat < 128 || curBeat >= 192 && curBeat < 320))
					zoomin();
			case 'madness-old':
				if (curBeat == 512)
					madnesseffect();
			case 'improbable-outset-upside':
				if (curBeat % 2 == 0
					&& curBeat % 4 != 0
					&& (curBeat >= 64 && curBeat < 128 || curBeat >= 160 && curBeat < 256 || curBeat >= 288 && curBeat < 352)
					&& !(curBeat >= 92 && curBeat < 96 || curBeat >= 188 && curBeat < 192 || curBeat >= 244 && curBeat < 248 || curBeat >= 252
						&& curBeat < 256 || curBeat >= 340 && curBeat < 344))
					zoomin();
				if (curBeat % 8 == 0
					&& (curBeat < 64 || curBeat >= 96 && curBeat < 160 || curBeat >= 192 && curBeat < 256 || curBeat >= 288 && curBeat <= 352))
					upsidezoom();
		}

		if (!FlxG.save.data.lowend)
			if (SONG.stage == 'auditor-hell')
				if (curBeat % 8 == 4)
					doClone(FlxG.random.int(0, 1));

		if (curBeat % 4 == 0)
			zoomin();

		if (curBeat % 2 == 0)
		{
			dadsinging = false;
			bfsinging = false;
		}

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (!bf.animation.curAnim.name.startsWith("sing") && !bf.animation.curAnim.name.startsWith('scared'))
			bf.playAnim('idle');

		if (curBeat == 532 && SONG.song.toLowerCase() == "expurgation")
			opp.playAnim('Hank', true);

		if (curBeat == 536 && SONG.song.toLowerCase() == "expurgation")
			opp.playAnim('idle', true);
		lastBeatHit = curBeat;
	}

	function iconBop(icon:FlxSprite)
		if (!grabbed && icon.scale.x <= 1.1 && curBeat % 2 == 0 && !FlxG.save.data.lowend && (icon == iconP1 || icon == iconP2))
		{
			icon.scale.set(1.2, 1.2);
			icon.updateHitbox();
		}

	function zoomin() // lol
		if (camGame.zoom < 1.35)
		{
			if (!ignoreDefaultZoom) // :D
				camGame.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

	public function pixels(enabled:Bool)
	{
		FlxG.game.stage.quality = enabled ? LOW : BEST;

		for (camera in FlxG.cameras.list)
		{
			camera.pixelPerfectRender = enabled;
			camera.antialiasing = !enabled;
		}

		for (member in members)
		{
			if (!(member is FlxSprite && member is FlxGroup))
				return;
			var sprite:FlxSprite = cast(member, FlxSprite);
			if (sprite != null && sprite.exists && sprite != iconP1 && sprite != iconP2 && sprite != healthBar && sprite != healthBarBG && sprite != spookyText) // dont ask, please.
				sprite.pixelPerfectRender = sprite.pixelPerfectPosition = enabled;
		}
	}

	function upsidezoom()
	{
		ignoreDefaultZoom = true;
		FlxTween.cancelTweensOf(camGame);
		FlxTween.tween(camGame, {zoom: defaultCamZoom + 0.1}, beatTime * 2, {
			ease: FlxEase.quadInOut,
			onComplete: (tween:FlxTween) ->
			{
				FlxTween.tween(camGame, {zoom: defaultCamZoom}, beatTime * 2, {
					ease: FlxEase.quartInOut,
					onComplete: (tween:FlxTween) ->
					{
						ignoreDefaultZoom = false;
					}
				});
			}
		});
		pixels(true);
		camGame.filters = [
			new ShaderFilter(distortion.shader),
			new ShaderFilter(blur.shader),
			new ShaderFilter(mosaic.shader)
		];
		FlxTween.cancelTweensOf(mosaic);
		FlxTween.tween(mosaic, {pixelSize: daPixelZoom}, beatTime * 2, {
			ease: FlxEase.quadInOut,
			onComplete: (tween:FlxTween) ->
			{
				FlxTween.tween(mosaic, {pixelSize: 1}, beatTime * 2, {
					ease: FlxEase.quartInOut,
					onComplete: (tween:FlxTween) ->
					{
						pixels(FlxG.save.data.lowend);
						mosaic.updateShaderResolution(1);
						camGame.filters = [new ShaderFilter(distortion.shader), new ShaderFilter(blur.shader)];
					}
				});
			}
		});
	}

	function madnesseffect()
	{
		FlxTween.tween(behindCharacters, {alpha: 1}, beatTime);
		FlxTween.tween(this, {burningnotealpha: 0.8}, beatTime * 2);
		FlxTween.tween(blur, {multiplier: 0.4}, 1);
		FlxTween.tween(distortion, {multiplier: 0.8}, 1);
		FlxTween.tween(iconP1, {alpha: 0}, beatTime * 4);
		FlxTween.tween(iconP2, {alpha: 0}, beatTime * 4);
		FlxTween.tween(scoreTxt, {alpha: 0}, beatTime * 4);
		FlxTween.tween(judgementCounter, {alpha: 0}, beatTime * 4);

		defaultCamZoom = 0.85;
		hardermode = true;
		FlxTween.tween(colorSwap, {hue: ogOffset}, beatTime);
	}
}
