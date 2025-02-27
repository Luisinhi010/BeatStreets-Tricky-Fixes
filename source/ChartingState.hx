package;

import sys.FileSystem;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.addons.ui.FlxUISlider;
import flixel.util.FlxTimer;
import sys.thread.Thread;
import flixel.math.FlxRect;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import Conductor.BPMChangeEvent;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import flixel.sound.FlxSound;
import flixel.util.FlxStringUtil;

using StringTools;

class ChartingState extends MusicBeatState
{
	function copySwagSection(section:SwagSection):SwagSection
	{
		return {
			lengthInSteps: section.lengthInSteps,
			bpm: section.bpm,
			changeBPM: section.changeBPM,
			mustHitSection: section.mustHitSection,
			gfSection: section.gfSection,
			sectionNotes: section.sectionNotes.copy(),
			typeOfSection: section.typeOfSection,
			altAnim: section.altAnim
		};
	}

	// Constants
	private static final GRID_SIZE_BASE:Int = 40;
	private static var GRID_SIZE:Int = GRID_SIZE_BASE;
	private static var DEFAULT_SECTION_LENGTH:Int = 16;
	private static var MAX_UNDO_STACK_SIZE:Int = 100;
	private static var SNAP_VALUES:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
	private static var COLOR_LIST:Array<FlxColor> = [
		FlxColor.fromRGB(255, 54, 54), FlxColor.fromRGB(167, 69, 255), FlxColor.fromRGB(10, 228, 174), FlxColor.fromRGB(157, 255, 85)
	];
	private static var NOTE_PREVIEW_SIZE:Int = 25;

	// Variables
	private var _file:FileReference;
	private var UI_box:FlxUITabMenu;
	private var curSection:Int = 0;
	public static var lastSection:Int = 0;
	private var bpmTxt:FlxText;
	private var strumLine:FlxSprite;
	private var curSong:String = 'Dadbattle';
	private var gridBG:FlxSprite;
	private var _song:SwagSong;
	private var typingShit:FlxInputText;
	private var curSelectedNote:Array<Dynamic>;
	private var tempBpm:Int = 0;
	private var vocals:FlxSound;
	private var leftIcon:HealthIcon;
	private var rightIcon:HealthIcon;
	private var bgGroup:FlxGroup;
	private var leftText:FlxText;
	private var metronome:FlxSound;
	private var isMetronomeActive:Bool = false;
	private var curSnapIndex:Int = 0;
	private var beatText:FlxText;
	private var songStats:FlxText;
	private var copyPasteMode:Bool = false;
	private var copiedNotes:Array<Array<Dynamic>> = [];
	private var selectionBox:FlxSprite;
	private var startMousePos:FlxPoint;
	private var isDragging:Bool = false;
	private var draggedNotes:Array<Note> = [];
	private var quantization:Int = 16;
	private var autoSaveTimer:FlxTimer;
	private var autoSaveInterval:Float = 60;
	private var showHitbox:Bool = false;
	private var showGrid:Bool = true;
	private var characterList:Array<String>;
	private var statusText:FlxText;
	private var dummyArrow:FlxSprite;
	private var bullshitUI:FlxGroup;
	private var metronomeTick:Int = 0;
	private var snapValues:Array<Int> = SNAP_VALUES;
	private var previewNote:FlxSprite;
	private var markers:Map<Float, String>;
	private var markerTexts:FlxTypedGroup<FlxText>;
	private var notePreviewEnabled:Bool = true;
	private var gridSnapEnabled:Bool = true;
	private var currentZoom:Float = 1.0;
	private var timeMarker:FlxSprite;
	private var timeText:FlxText;
	private var helpTxt:FlxText;

	// Flixel Groups
	private var curRenderedNotes:FlxTypedGroup<Note>;
	private var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	private var curRenderedBurning:FlxTypedGroup<FlxSprite>;

	// UI elements
	private var stepperLength:FlxUINumericStepper;
	private var check_mustHitSection:FlxUICheckBox;
	private var check_gfSection:FlxUICheckBox;
	private var check_changeBPM:FlxUICheckBox;
	private var stepperSectionBPM:FlxUINumericStepper;
	private var check_altAnim:FlxUICheckBox;
	private var stepperSusLength:FlxUINumericStepper;

	// Playback variables
	private var playbackSpeed:Float = 1.0;
	private var isLooping:Bool = false;
	private var loopStart:Float = 0;
	private var loopEnd:Float = 0;
	private var showHitZones:Bool = false;
	private var hitZoneSprites:FlxTypedGroup<FlxSprite>;
	private var bpmLines:FlxTypedGroup<FlxSprite>;
	private var beatLines:FlxTypedGroup<FlxSprite>;
	private var mirrorMode:Bool = false;

	// Undo/Redo stacks
	private var undoStack:Array<SwagSection> = [];
	private var redoStack:Array<SwagSection> = [];


	override function create()
	{
		try {

			trace('ChartingState: Starting create()');
			curSection = lastSection;

			bgGroup = new FlxGroup();
			add(bgGroup);

			if (!FlxG.save.data.lowend)
			{
				Thread.create(function()
				{
					var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
					bg.scrollFactor.set();
					bg.screenCenter();
					bg.y += 40;
					bgGroup.add(bg);
					var shade:FlxSprite = new FlxSprite(-205, -100).loadGraphic(Paths.image('menu/freeplay/Shadescreen', 'clown'));
					shade.scrollFactor.set();
					shade.setGraphicSize(Std.int(shade.width * 0.65));
					bgGroup.add(shade);
					var bars:FlxSprite = new FlxSprite(-225, -395).loadGraphic(Paths.image('menu/freeplay/theBox', 'clown'));
					bars.scrollFactor.set();
					bars.setGraphicSize(Std.int(bars.width * 0.65));
					bgGroup.add(bars);
					var darkBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					darkBG.screenCenter();
					darkBG.scrollFactor.set();
					darkBG.alpha = 0.4;
					bgGroup.add(darkBG);
				});
			}
			
			GRID_SIZE = Std.int(GRID_SIZE_BASE * (16 / quantization)); // Calculate GRID_SIZE based on quantization
			gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 16);
			gridBG.screenCenter(X);
			gridBG.x = gridBG.width / 4;
			gridBG.x -= GRID_SIZE * 2;
			add(gridBG);

			leftIcon = new HealthIcon('bf');
			rightIcon = new HealthIcon('Tricky');
			leftIcon.scrollFactor.set(1, 1);
			rightIcon.scrollFactor.set(1, 1);

			leftIcon.setGraphicSize(0, 45);
			rightIcon.setGraphicSize(0, 45);

			add(leftIcon);
			add(rightIcon);

			leftIcon.setPosition(0, -100);
			rightIcon.setPosition(gridBG.width / 2, -100);

			var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width / 2).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
			add(gridBlackLine);

			curRenderedNotes = new FlxTypedGroup<Note>();
			curRenderedSustains = new FlxTypedGroup<FlxSprite>();
			curRenderedBurning = new FlxTypedGroup<FlxSprite>();


			if (PlayState.SONG != null)
				_song = PlayState.SONG;
			else
			{
				_song = {
					song: 'Test',
					notes: [],
					bpm: 150,
					needsVoices: true,
					player1: 'bf',
					player2: 'Tricky',
					gfVersion: 'gf',
					speed: 1,
					stage: 'nevada',
					haloNotes: false
				};
			}

			FlxG.mouse.visible = true;
			FlxG.save.bind('funkin', 'ninjamuffin99');

			tempBpm = _song.bpm;

			addSection();

			// sections = _song.notes;

			updateGrid();

			loadSong(_song.song);
			Conductor.changeBPM(_song.bpm);
			Conductor.mapBPMChanges(_song);

			bpmTxt = new FlxText(1000, 50, 0, "", 16);
			bpmTxt.scrollFactor.set();
			add(bpmTxt);

			strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(FlxG.width / 2), 4);
			add(strumLine);

			dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
			add(dummyArrow);

			var tabs = [
				{name: "Song", label: 'Song'},
				{name: "Section", label: 'Section'},
				{name: "Note", label: 'Note'},
				{name: "Chart", label: 'Chart'},
				{name: "Tools", label: 'Tools'},
				{name: "Playback", label: 'Playback'}
			];

			UI_box = new FlxUITabMenu(null, tabs, true);
			UI_box.resize(300, FlxG.height - 100);
			UI_box.x = FlxG.width - UI_box.width - 20;
			UI_box.y = 20;
			UI_box.color = FlxColor.fromRGB(100, 100, 100);
			UI_box.scrollFactor.set();
			add(UI_box);

			leftText = new FlxText(10, 10, 280, "", 16);
			leftText.setFormat("vcr.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			leftText.borderSize = 2;
			leftText.scrollFactor.set();
			add(leftText);

			var shortcuts:FlxText = new FlxText(10, FlxG.height
				- 200, 280,
				"CTRL+Z - Undo\n"
				+ "CTRL+Y - Redo\n"
				+ "CTRL+C - Copy Section\n"
				+ "CTRL+V - Paste Section\n"
				+ "ALT - Place Burn Note\n"
				+ "SHIFT - Quick Scroll\n"
				+ "SPACE - Play/Pause\n"
				+ "R - Reset Section\n"
				+ "CTRL+S - Quick Save\n"
				+ "1-9 - Change Grid Snap\n"
				+ "CTRL+C - Copy Selection\n"
				+ "CTRL+V - Paste Selection\n"
				+ "CTRL+X - Cut Selection\n"
				+ "ALT+Arrow Keys - Nudge Notes\n"
				+ "DELETE - Delete Selection\n"
				+ "SHIFT+Click+Drag - Select Multiple Notes\n"
				+ "CTRL+D - Duplicate Selection\n"
				+ "CTRL+A - Select All Notes",
				16);
			shortcuts.setFormat("vcr.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			shortcuts.borderSize = 2;
			shortcuts.scrollFactor.set();
			add(shortcuts);

			beatText = new FlxText(10, 610, 0, "Beat: 0 / Step: 0", 20);
			beatText.setFormat("vcr.ttf", 20, FlxColor.WHITE, LEFT);
			beatText.scrollFactor.set();
			add(beatText);

			songStats = new FlxText(10, 0, 0, "", 20);
			songStats.setFormat("vcr.ttf", 20, FlxColor.WHITE, LEFT);
			songStats.screenCenter(Y);
			songStats.scrollFactor.set();
			add(songStats);

			addSongUI();
			addSectionUI();
			addNoteUI();
			addChartUI();
			addToolsUI();
			addPlaybackUI();
			updateHeads();

			add(curRenderedNotes);
			add(curRenderedSustains);
			add(curRenderedBurning);

			super.create();

			initUndoRedo();
			if (!FlxG.save.data.lowend)
			{
				var menuShade:FlxSprite = new FlxSprite(-1350, -1190).loadGraphic(Paths.image("menu/freeplay/Menu Shade", 'clown'));
				menuShade.scrollFactor.set();
				menuShade.setGraphicSize(Std.int(menuShade.width * 0.7));
				add(menuShade);
			}

			metronome = FlxG.sound.load(Paths.sound('metronome'));

			selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLUE);
			selectionBox.alpha = 0.4;
			selectionBox.visible = false;
			add(selectionBox);

			songStats.text += '\nQuantization: 1/${quantization}';

			characterList = loadAvailableCharacters();

			statusText = new FlxText(10, FlxG.height - 30, FlxG.width - 20);
			statusText.setFormat(null, 14, FlxColor.WHITE, RIGHT);
			statusText.scrollFactor.set();
			statusText.borderStyle = OUTLINE;
			statusText.borderColor = FlxColor.BLACK;
			add(statusText);
			trace('ChartingState: Finished create()');
			
			setupEditorTools();
			setupVisualGuides();
		} catch(e:Dynamic) {
			trace('ChartingState: Error in create() - ' + e);
			MainMenuState.reRoll();
			FlxG.switchState(new MainMenuState());
		}
	}

	function setupEditorTools() {
		// Preview de nota
		previewNote = new FlxSprite().makeGraphic(NOTE_PREVIEW_SIZE, NOTE_PREVIEW_SIZE, FlxColor.GRAY);
		previewNote.alpha = 0.6;
		add(previewNote);

		// Marcador de tempo
		timeMarker = new FlxSprite(0, 0).makeGraphic(Std.int(gridBG.width), 4, FlxColor.WHITE);
		timeMarker.alpha = 0.4;
		add(timeMarker);

		// Texto de tempo
		timeText = new FlxText(gridBG.x + gridBG.width + 5, 0, 0, "00:00", 16);
		add(timeText);

		// Grupo de marcadores
		markerTexts = new FlxTypedGroup<FlxText>();
		add(markerTexts);
		
		// Texto de ajuda flutuante
		helpTxt = new FlxText(0, 0, 250);
		helpTxt.setFormat(null, 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE);
		helpTxt.borderColor = FlxColor.BLACK;
		helpTxt.alpha = 0.8;
		helpTxt.visible = false;
		add(helpTxt);
	}

	function setupVisualGuides() {
		hitZoneSprites = new FlxTypedGroup<FlxSprite>();
		bpmLines = new FlxTypedGroup<FlxSprite>();
		beatLines = new FlxTypedGroup<FlxSprite>();
		
		add(bpmLines);
		add(beatLines);
		add(hitZoneSprites);
		
		updateVisualGuides();
	}

	function updateVisualGuides() {
		// Limpar guias existentes
		bpmLines.clear();
		beatLines.clear();
		hitZoneSprites.clear();
		
		// Adicionar linhas de BPM
		var bpmInterval = (60 / _song.bpm) * 1000;
		var currentTime = 0.0;
		
		while (currentTime < FlxG.sound.music.length) {
			var yPos = getYfromStrum(currentTime, _song.notes[curSection].lengthInSteps);
			var line = new FlxSprite(gridBG.x, yPos).makeGraphic(Std.int(gridBG.width), 2, 0x44FFFFFF);
			bpmLines.add(line);
			currentTime += bpmInterval;
		}
		
		// Adicionar linhas de beat
		for (i in 0...(_song.notes[curSection].lengthInSteps * 4)) {
			var yPos = gridBG.y + (i * GRID_SIZE / 4);
			var alpha = (i % 4 == 0) ? 0.4 : 0.2;
			var line = new FlxSprite(gridBG.x, yPos).makeGraphic(Std.int(gridBG.width), 1, FlxColor.WHITE);
			line.alpha = alpha;
			beatLines.add(line);
		}
		
		// Adicionar hit zones se ativado
		if (showHitZones) {
			for (note in curRenderedNotes) {
				var hitZone = new FlxSprite(note.x - 10, note.y - 10)
					.makeGraphic(GRID_SIZE + 20, GRID_SIZE + 20, 0x33FF0000);
				hitZoneSprites.add(hitZone);
			}
		}
	}

	function initUndoRedo()
	{
		if (FlxG.save.data.sectionBackups == null)
			FlxG.save.data.sectionBackups = [];

		undoStack = FlxG.save.data.sectionBackups;
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.song, 8);
		typingShit = UI_songTitle;

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
			trace('CHECKED!');
		};

		var saveButton:FlxButton = new FlxButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxButton = new FlxButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			loadSong(_song.song);
		});

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.song.toLowerCase());
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSongJson.x, reloadSongJson.y + 30, 'load autosave', loadAutosave);

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 339, 0);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';

		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('characterList'));

		var player1DropDown = new FlxUIDropDownMenu(10, stepperSpeed.y + 45, 
			FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true),
			function(character:String) {
				_song.player1 = characterList[Std.parseInt(character)];
				updateHeads();
				showToast('Player 1 changed to: ${_song.player1}');
			});

		var gfVersionDropDown = new FlxUIDropDownMenu(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true),
			function(character:String)
			{
				_song.gfVersion = characters[Std.parseInt(character)];
				updateHeads();
			});
		gfVersionDropDown.selectedLabel = _song.gfVersion;

		var player2DropDown = new FlxUIDropDownMenu(player1DropDown.x + 140, player1DropDown.y + 40,
			FlxUIDropDownMenu.makeStrIdLabelArray(characterList, true),
			function(character:String) {
				_song.player2 = characterList[Std.parseInt(character)];
				updateHeads();
				showToast('Player 2 changed to: ${_song.player2}');
			});

		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('stageList'));

		var stageDropDown = new FlxUIDropDownMenu(player2DropDown.x, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true),
			function(character:String)
			{
				_song.stage = stages[Std.parseInt(character)];
			});
		stageDropDown.selectedLabel = _song.stage;

		var check_mute_inst = new FlxUICheckBox(player1DropDown.x, player2DropDown.y + 40, null, null, "Mute Instrumental", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};

		var check_mute_vocals = new FlxUICheckBox(stageDropDown.x, check_mute_inst.y, null, null, "Mute Vocals", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			if (vocals != null)
			{
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
			}
		};

		var check_halo = new FlxUICheckBox(check_mute_vocals.x, check_mute_vocals.y + 40, null, null, "Halo Notes", 100);
		check_halo.checked = _song.haloNotes;
		check_halo.callback = function()
		{
			_song.haloNotes = check_halo.checked;
		};

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_song.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_song.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Character:'));
		tab_group_song.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));

		tab_group_song.add(check_voices);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(player1DropDown);
		tab_group_song.add(gfVersionDropDown);
		tab_group_song.add(player2DropDown);
		tab_group_song.add(stageDropDown);
		tab_group_song.add(check_halo);
		tab_group_song.add(check_mute_inst);
		tab_group_song.add(check_mute_vocals);

		UI_box.addGroup(tab_group_song);
		UI_box.scrollFactor.set();

		FlxG.camera.follow(strumLine);
	}

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = "section_length";

		check_mustHitSection = new FlxUICheckBox(stepperLength.x, stepperLength.y + 20, null, null, "Must hit section", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = true;

		check_gfSection = new FlxUICheckBox(check_mustHitSection.x + check_mustHitSection.width + 20, check_mustHitSection.y, null, null, "Gf section", 100);
		check_gfSection.name = 'check_gfSection';
		check_gfSection.checked = false;

		check_changeBPM = new FlxUICheckBox(check_mustHitSection.x, check_mustHitSection.y + 20, null, null, 'Change BPM', 100);
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(check_mustHitSection.x, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 0);
		stepperSectionBPM.value = Conductor.bpm;
		stepperSectionBPM.name = 'section_bpm';

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(10, 130, 1, 1, -999, 999, 0);

		var copyButton:FlxButton = new FlxButton(10, 130, "Copy last", function()
		{
			copySection(Std.int(stepperCopy.value));
		});

		stepperCopy.x = copyButton.x + copyButton.width + 10;

		var clearSectionButton:FlxButton = new FlxButton(10, 150, "Clear", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function()
			{
				clearSection();
			}, null));
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		var swapSection:FlxButton = new FlxButton(10, 170, "Swap section", swaptheSection);

		var swapFocus:FlxButton = new FlxButton(swapSection.x + swapSection.width + 10, 170, "Swap focus", function()
		{
			check_mustHitSection.checked = !check_mustHitSection.checked;
			_song.notes[curSection].mustHitSection = check_mustHitSection.checked;
			swaptheSection();
			updateHeads();
		});
		swapFocus.color = FlxColor.CYAN;
		swapFocus.label.color = FlxColor.WHITE;

		check_altAnim = new FlxUICheckBox(10, 400, null, null, "Alt Animation", 100);
		check_altAnim.name = 'check_altAnim';

		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);
		tab_group_section.add(swapFocus);

		UI_box.addGroup(tab_group_section);
	}

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16 * 3);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';

		var applyLength:FlxButton = new FlxButton(100, 10, 'Apply');

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(applyLength);

		UI_box.addGroup(tab_group_note);
	}

	function addChartUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Chart";

		var copySectionButton = new FlxButton(10, 30, "Copy Section", function()
		{
			copySection();
		});

		var pasteSectionButton = new FlxButton(copySectionButton.x + 100, 30, "Paste Section", function()
		{
			if (copiedNotes.length > 0)
				pasteNotes();
		});

		var clearSectionButton = new FlxButton(10, 60, "Clear Section", function()
		{
			clearSection();
		});

		var swapSectionButton = new FlxButton(clearSectionButton.x + 100, 60, "Swap Section", function()
		{
			swaptheSection();
		});

		var showHitboxCheck = new FlxUICheckBox(10, 90, null, null, "Show Hitboxes", 100);
		showHitboxCheck.checked = showHitbox;
		showHitboxCheck.callback = function()
		{
			showHitbox = showHitboxCheck.checked;
			updateGrid();
		};

		var showGridCheck = new FlxUICheckBox(10, 120, null, null, "Show Grid", 100);
		showGridCheck.checked = showGrid;
		showGridCheck.callback = function()
		{
			showGrid = showGridCheck.checked;
			gridBG.visible = showGrid;
		};

		var snapSteppers = new FlxUINumericStepper(10, 150, 4, quantization, 4, 192, 0);
		snapSteppers.value = quantization;
		snapSteppers.name = 'snap_stepper';

		tab_group.add(new FlxText(snapSteppers.x, snapSteppers.y - 15, 0, 'Snap: (Beat Divisions)'));
		tab_group.add(snapSteppers);
		tab_group.add(copySectionButton);
		tab_group.add(pasteSectionButton);
		tab_group.add(clearSectionButton);
		tab_group.add(swapSectionButton);
		tab_group.add(showHitboxCheck);
		tab_group.add(showGridCheck);

		UI_box.addGroup(tab_group);
	}

	function addToolsUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Tools";

		// Auto-save
		var autoSaveCheck = new FlxUICheckBox(10, 30, null, null, "Auto-Save", 100);
		autoSaveCheck.checked = false;
		autoSaveCheck.callback = function()
		{
			if (autoSaveCheck.checked)
			{
				autoSaveTimer = new FlxTimer().start(autoSaveInterval, function(tmr:FlxTimer)
				{
					autosaveSong();
				}, 0);
			}
			else if (autoSaveTimer != null)
			{
				autoSaveTimer.cancel();
			}
		};

		tab_group.add(autoSaveCheck);

		UI_box.addGroup(tab_group);
	}

	function addPlaybackUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Playback";

		// playback
		var playButton = new FlxButton(10, 60, "Play", function()
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.play();
				if (vocals != null)
					vocals.play();
			}
		});

		var pauseButton = new FlxButton(playButton.x + 100, 60, "Pause", function()
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (vocals != null)
					vocals.pause();
			}
		});

		var restartButton = new FlxButton(10, 90, "Restart", function()
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.time = 0;
				if (vocals != null)
					vocals.time = 0;
				Conductor.songPosition = 0;
				updateGrid();
			}
		});

		// Metronome
		var metronomeCheck = new FlxUICheckBox(10, 120, null, null, "Metronome", 100);
		metronomeCheck.checked = isMetronomeActive;
		metronomeCheck.callback = function()
		{
			isMetronomeActive = metronomeCheck.checked;
			metronomeTick = 0;
		};

		// Velocidade de playback
		var speedSlider = new FlxUISlider(this, 'playbackSpeed',
			10, 150, 0.25, 3.0, 200, 20, 5, 0xFF888888, 0xFF000000);
		speedSlider.nameLabel.text = 'Playback Speed';
		speedSlider.callback = function(value:Float) {
			FlxG.sound.music.pitch = value;
			vocals.pitch = value;
		};
		
		// Loop controls
		var loopCheck = new FlxUICheckBox(10, 180, null, null, "Enable Loop", 100);
		loopCheck.callback = function() {
			isLooping = loopCheck.checked;
			if (isLooping) {
				loopStart = Conductor.songPosition;
				showToast("Loop Start Set", FlxColor.GREEN);
			}
		};
		
		var setLoopEndBtn = new FlxButton(120, 180, "Set Loop End", function() {
			if (isLooping) {
				loopEnd = Conductor.songPosition;
				showToast("Loop End Set", FlxColor.GREEN);
			}
		});
		
		// Visual guides
		var showHitZonesCheck = new FlxUICheckBox(10, 210, null, null, "Show Hit Zones", 100);
		showHitZonesCheck.callback = function() {
			showHitZones = showHitZonesCheck.checked;
			updateVisualGuides();
		};
		
		// Mirror mode
		var mirrorCheck = new FlxUICheckBox(10, 240, null, null, "Mirror Mode", 100);
		mirrorCheck.callback = function() {
			mirrorMode = mirrorCheck.checked;
		};

		tab_group.add(playButton);
		tab_group.add(pauseButton);
		tab_group.add(restartButton);
		tab_group.add(metronomeCheck);
		tab_group.add(speedSlider);
		tab_group.add(loopCheck);
		tab_group.add(setLoopEndBtn);
		tab_group.add(showHitZonesCheck);
		tab_group.add(mirrorCheck);

		UI_box.addGroup(tab_group);
	}

	function loadSong(daSong:String):Void {
    try {
        cleanupAudio();
        
        var instPath = Paths.inst(daSong);
        if (!Assets.exists(instPath)) {
            showToast('Instrumental not found!', FlxColor.RED);
            return;
        }

        FlxG.sound.playMusic(instPath, 0.6, false);
        if (_song.needsVoices) {
            vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
            FlxG.sound.list.add(vocals);
        } else {
            vocals = new FlxSound();
        }
        
        vocals.exists = true;
        FlxG.sound.music.pause();
        vocals.pause();
        
        Conductor.changeBPM(_song.bpm);
    } catch(e) {
        trace('Error loading song: $e');
        showToast('Error loading song!', FlxColor.RED);
    }
}

private function cleanupAudio():Void {
    if (FlxG.sound.music != null) {
        FlxG.sound.music.stop();
        FlxG.sound.music = null;
    }
    if (vocals != null) {
        vocals.stop();
        vocals.destroy();
        vocals = null;
    }
}

	function generateUI():Void
	{
		while (bullshitUI.members.length > 0)
		{
			bullshitUI.remove(bullshitUI.members[0], true);
		}

		// general shit
		var title:FlxText = new FlxText(UI_box.x + 20, UI_box.y + 20, 0);
		bullshitUI.add(title);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section':
					_song.notes[curSection].mustHitSection = check.checked;
					updateHeads();

				case 'Gf section':
					_song.notes[curSection].gfSection = check.checked;

				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');

				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'song_speed')
			{
				_song.speed = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				tempBpm = Std.int(nums.value);
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(Std.int(nums.value));
			}
			else if (wname == 'note_susLength')
			{
				curSelectedNote[2] = nums.value;
				updateGrid();
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = Std.int(nums.value);
				updateGrid();
			}
			else if (wname == 'snap_stepper')
			{
				quantization = Std.int(nums.value);
				GRID_SIZE = Std.int(GRID_SIZE_BASE * (16 / quantization)); // Calculate GRID_SIZE based on quantization
				updateGrid();
				songStats.text = 'Song Time: ${Std.int(Conductor.songPosition / 1000)}s\n' + 'Section: ${curSection}\n' + 'Snap: 1/${quantization}';
			}
		}
	}

	function sectionStartTime():Float
	{
		var daBPM:Int = _song.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection)
		{
			if (_song.notes[i].changeBPM)
				daBPM = _song.notes[i].bpm;
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	override function update(elapsed:Float)
	{
		try {
			if (!FlxG.sound.music.playing) {
				Conductor.songPosition += elapsed * 1000;
			}
			
			curStep = recalculateSteps();

			Conductor.songPosition = FlxG.sound.music.time;
			_song.song = typingShit.text;

			strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps), _song.notes[curSection].lengthInSteps);

			if (curBeat % 4 == 0 && curStep >= 16 * (curSection + 1))
			{
				trace(curStep);
				trace((_song.notes[curSection].lengthInSteps) * (curSection + 1));
				trace('DUMBSHIT');

				if (_song.notes[curSection + 1] == null)
				{
					addSection();
				}

				changeSection(curSection + 1, false);
			}

			FlxG.watch.addQuick("Song", _song.song);
			FlxG.watch.addQuick("Section", curSection);
			FlxG.watch.addQuick("beathit", curBeat);
			FlxG.watch.addQuick("stephit", curStep);
			FlxG.watch.addQuick("character", _song.player2);
			FlxG.watch.addQuick("bf-character", _song.player1);

			if (FlxG.mouse.justPressed)
			{
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					curRenderedNotes.forEach(function(note:Note)
					{
						if (FlxG.mouse.overlaps(note))
						{
							if (FlxG.keys.pressed.CONTROL)
								selectNote(note);
							else
								deleteNote(note);
						}
					});
				}
				else
				{
					if (FlxG.mouse.x > gridBG.x
						&& FlxG.mouse.x < gridBG.x + gridBG.width
						&& FlxG.mouse.y > gridBG.y
						&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps))
					{
						FlxG.log.add('added note');
						addNote();
					}
				}
			}

			if (FlxG.mouse.x > gridBG.x
				&& FlxG.mouse.x < gridBG.x + gridBG.width
				&& FlxG.mouse.y > gridBG.y
				&& FlxG.mouse.y < gridBG.y + gridBG.height)
			{
				dummyArrow.x = Math.floor((FlxG.mouse.x - gridBG.x) / GRID_SIZE) * GRID_SIZE + gridBG.x;
				if (FlxG.keys.pressed.SHIFT)
					dummyArrow.y = FlxG.mouse.y;
				else
					dummyArrow.y = Math.floor((FlxG.mouse.y - gridBG.y) / GRID_SIZE) * GRID_SIZE + gridBG.y;
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				lastSection = curSection;

				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				vocals.stop();
				FlxG.switchState(new PlayState());
				FlxG.mouse.visible = false;
			}

			if (FlxG.keys.justPressed.E)
			{
				changeNoteSustain(Conductor.stepCrochet);
			}
			if (FlxG.keys.justPressed.Q)
			{
				changeNoteSustain(-Conductor.stepCrochet);
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;
					if (UI_box.selected_tab < 0)
						UI_box.selected_tab = 2;
				}
				else
				{
					UI_box.selected_tab += 1;
					if (UI_box.selected_tab >= 3)
						UI_box.selected_tab = 0;
				}
			}

			if (!typingShit.hasFocus)
			{
				if (FlxG.keys.justPressed.SPACE)
				{
					if (FlxG.sound.music.playing)
					{
						FlxG.sound.music.pause();
						vocals.pause();
					}
					else
					{
						vocals.play();
						FlxG.sound.music.play();
					}
				}

				if (FlxG.keys.justPressed.R)
				{
					if (FlxG.keys.pressed.SHIFT)
						resetSection(true);
					else
						resetSection();
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.music.pause();
					vocals.pause();

					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
					vocals.time = FlxG.sound.music.time;
				}

				if (!FlxG.keys.pressed.SHIFT)
				{
					if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
					{
						FlxG.sound.music.pause();
						vocals.pause();

						var daTime:Float = 700 * FlxG.elapsed;

						if (FlxG.keys.pressed.W)
						{
							FlxG.sound.music.time -= daTime;
						}
						else
							FlxG.sound.music.time += daTime;

						vocals.time = FlxG.sound.music.time;
					}
				}
				else
				{
					if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
					{
						FlxG.sound.music.pause();
						vocals.pause();

						var daTime:Float = Conductor.stepCrochet * 2;

						if (FlxG.keys.justPressed.W)
						{
							FlxG.sound.music.time -= daTime;
						}
						else
							FlxG.sound.music.time += daTime;

						vocals.time = FlxG.sound.music.time;
					}
				}
			}

			_song.bpm = tempBpm;

			var shiftThing:Int = 1;
			if (FlxG.keys.pressed.SHIFT)
				shiftThing = 4;
			if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
				changeSection(curSection + shiftThing);
			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
				changeSection(curSection - shiftThing);

			// Atualizar texto informativo
			leftText.text = 'Song: ${_song.song}\n'
				+ 'Section: $curSection\n'
				+ 'Step: $curStep\n'
				+ 'Beat: $curBeat\n'
				+ 'Snap: 1/${quantization}\n'
				+ 'Selected Note: ${curSelectedNote != null ? curSelectedNote[0] : "None"}\n';

			// Atalhos adicionais
			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.Z && undoStack.length > 0)
					undoLastAction();

				if (FlxG.keys.justPressed.S)
					autosaveSong();

				if (FlxG.keys.justPressed.D && draggedNotes.length > 0)
					duplicateNotes();

				if (FlxG.keys.justPressed.A)
					selectAllNotes();
			}

			bpmTxt.text = bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
				+ " / "
				+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
				+ "\nSong: "
				+ _song.song
				+ "\nSection: "
				+ curSection
				+ "\nCurStep: "
				+ curStep
				+ "\nCurBeat: "
				+ curBeat
				+ "\nCharacter: "
				+ _song.player2
				+ "\nbf-Character: "
				+ _song.player1;

			if (FlxG.keys.justPressed.M)
			{
				isMetronomeActive = !isMetronomeActive;
				metronomeTick = 0;
			}

			for (i in 0...snapValues.length)
			{
				if (FlxG.keys.anyJustPressed([49 + i]))
				{
					curSnapIndex = i;
					 GRID_SIZE = Std.int(40 * (snapValues[curSnapIndex] / 16));
					updateGrid();
				}
			}

			beatText.text = 'Beat: ${curBeat} / Step: ${curStep}';
			songStats.text = 'Song Time: ${Std.int(Conductor.songPosition / 1000)}s\n' + 'Section: ${curSection}\n' + 'Snap: 1/${snapValues[curSnapIndex]}';

			if (isMetronomeActive && FlxG.sound.music.playing)
			{
				var Time = Math.abs(Conductor.songPosition);
				var Beat = Math.floor(Time / Conductor.crochet);

				if (Beat > metronomeTick)
				{
					metronome.play(true);
					metronomeTick = Beat;
				}
			}

			if (FlxG.mouse.pressed && FlxG.keys.pressed.SHIFT)
			{
				if (!isDragging)
				{
					isDragging = true;
					startMousePos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
					selectionBox.visible = true;
				}

				var currentMousePos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);
				var selectionWidth = Math.abs(currentMousePos.x - startMousePos.x);
				var selectionHeight = Math.abs(currentMousePos.y - startMousePos.y);

				selectionBox.x = Math.min(startMousePos.x, currentMousePos.x);
				selectionBox.y = Math.min(startMousePos.y, currentMousePos.y);
				selectionBox.scale.set(selectionWidth, selectionHeight);

				curRenderedNotes.forEach(function(note:Note)
				{
					if (selectionBox.overlaps(note))
					{
						note.alpha = 0.5;
						if (!draggedNotes.contains(note))
							draggedNotes.push(note);
					}
					else
					{
						note.alpha = 1;
						draggedNotes.remove(note);
					}
				});
			}
			else if (isDragging)
			{
				isDragging = false;
				selectionBox.visible = false;
			}

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.C && draggedNotes.length > 0)
					copyNotes();
				else if (FlxG.keys.justPressed.V && copiedNotes.length > 0)
					pasteNotes();
				else if (FlxG.keys.justPressed.X && draggedNotes.length > 0)
				{
					copyNotes();
					deleteNotes();
				}
			}

			if (FlxG.keys.pressed.ALT)
			{
				var xOffset:Float = 0;
				var yOffset:Float = 0;

				if (FlxG.keys.justPressed.LEFT)
					xOffset = -GRID_SIZE;
				if (FlxG.keys.justPressed.RIGHT)
					xOffset = GRID_SIZE;
				if (FlxG.keys.justPressed.UP)
					yOffset = -GRID_SIZE;
				if (FlxG.keys.justPressed.DOWN)
					yOffset = GRID_SIZE;

				if (xOffset != 0 || yOffset != 0)
					nudgeNotes(xOffset, yOffset);
			}

			if (FlxG.keys.justPressed.DELETE)
				deleteNotes();

			for (i in 0...9)
			{
				if (FlxG.keys.anyJustPressed([49 + i]))
				{
					quantization = 4 * (i + 1);
					 GRID_SIZE = Std.int(40 * (16 / quantization));
					updateGrid();
					songStats.text = 'Song Time: ${Std.int(Conductor.songPosition / 1000)}s\n' + 'Section: ${curSection}\n' + 'Snap: 1/${quantization}';
				}
			}

			super.update(elapsed);

			if (FlxG.keys.pressed.CONTROL) {
				if (FlxG.mouse.wheel != 0) {
					var zoom = FlxG.camera.zoom;
					zoom += FlxG.mouse.wheel * 0.05;
					zoom = Math.max(0.1, Math.min(3.0, zoom));
					FlxTween.tween(FlxG.camera, {zoom: zoom}, 0.1, {
						ease: FlxEase.quadOut
					});
				}
			}

			if (curSelectedNote != null) {
				UIEffects.highlight(dummyArrow);
			}

			// Atualizar preview de nota
			if (notePreviewEnabled) {
				previewNote.visible = true;
				previewNote.x = Math.floor((FlxG.mouse.x - gridBG.x) / GRID_SIZE) * GRID_SIZE + gridBG.x;
				previewNote.y = FlxG.mouse.y;
				
				if (FlxG.keys.pressed.ALT)
					previewNote.color = FlxColor.RED;
				else 
					previewNote.color = FlxColor.GRAY;
			} else {
				previewNote.visible = false;
			}

			// Atualizar marcador de tempo
			timeMarker.y = getYfromStrum(Conductor.songPosition - sectionStartTime(), _song.notes[curSection].lengthInSteps);
			timeText.y = timeMarker.y - 8;
			timeText.text = FlxStringUtil.formatTime(Conductor.songPosition / 1000);

			// Atalhos adicionais
			if (FlxG.keys.pressed.CONTROL) {
				// Zoom
				if (FlxG.keys.pressed.SHIFT && FlxG.mouse.wheel != 0) {
					var zoom = currentZoom;
					zoom += FlxG.mouse.wheel * 0.1;
					zoom = FlxMath.bound(zoom, 0.5, 3.0);
					setZoom(zoom);
				}
				
				// Marcadores
				if (FlxG.keys.justPressed.M) {
					var time = getStrumTime(FlxG.mouse.y);
					if (!markers.exists(time)) {
						var name = FlxG.keys.pressed.SHIFT ? "Section " + curSection : Date.now().toString();
						addMarker(time, name);
					} else {
						removeMarker(time);
					}
				}
			}

			// Toggle preview
			if (FlxG.keys.justPressed.P) {
				notePreviewEnabled = !notePreviewEnabled;
				showToast("Note preview: " + (notePreviewEnabled ? "ON" : "OFF"));
			}

			// Toggle grid snap
			if (FlxG.keys.justPressed.G) {
				gridSnapEnabled = !gridSnapEnabled;
				showToast("Grid snap: " + (gridSnapEnabled ? "ON" : "OFF"));
			}

			// Mostrar ajuda ao passar o mouse
			if (FlxG.mouse.overlaps(UI_box)) {
				showHelpText("Right click for options\nScroll to navigate\nDouble click to edit", FlxG.mouse.x + 15, FlxG.mouse.y + 15);
			} else {
				hideHelpText();
			}

			if (isLooping && FlxG.sound.music.playing) {
				if (Conductor.songPosition >= loopEnd) {
					FlxG.sound.music.time = loopStart;
					vocals.time = loopStart;
					Conductor.songPosition = loopStart;
				}
			}
			
			// Atalho para mirror mode
			if (FlxG.keys.justPressed.M && FlxG.keys.pressed.SHIFT) {
				mirrorMode = !mirrorMode;
				showToast("Mirror Mode: " + (mirrorMode ? "ON" : "OFF"));
			}
		} catch(e:Dynamic) {
			trace('ChartingState: Error in update() - ' + e); 
			handleError("update", e);
		}
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		vocals.pause();

		// Basically old shit from changeSection???
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		vocals.time = FlxG.sound.music.time;
		updateCurStep();

		updateGrid();
		updateSectionUI();
	}

	function changeSection(sec:Int = 0, updateMusic:Bool = true):Void {
		try {
			trace('ChartingState: Changing to section ${sec}');
			if (_song.notes[sec] == null) return;

			curSection = sec;
			updateGrid();

			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();
				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}

			updateGrid();
			updateSectionUI();
			trace('ChartingState: Finished changing section');
		} catch(e:Dynamic) {
			trace('ChartingState: Error changing section - ' + e);
			throw e;
		}
	}

	function copySection(?sectionNum:Int = 1):Void {
        var daSec = FlxMath.maxInt(curSection, sectionNum);
        var sourceSection = _song.notes[daSec - sectionNum];
        var targetSection = _song.notes[daSec];

        if (sourceSection == null || targetSection == null) return;

        for (note in sourceSection.sectionNotes) {
            var strum = note[0] + Conductor.stepCrochet * (targetSection.lengthInSteps * sectionNum);
            targetSection.sectionNotes.push([strum, note[1], note[2], note[3]]);
        }

        updateGrid();
		showToast("Section copied", FlxColor.YELLOW);
    }

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	function updateHeads():Void
	{
		try {
			trace('ChartingState: Updating heads');
			if (check_mustHitSection.checked)
			{
				leftIcon.changeIcon(_song.player1);
				rightIcon.changeIcon(_song.player2);
			}
			else
			{
				leftIcon.changeIcon(_song.player2);
				rightIcon.changeIcon(_song.player1);
			}
			trace('ChartingState: Heads updated successfully');
		} catch(e:Dynamic) {
			trace('ChartingState: Error updating heads - ' + e);
			throw e;
		}
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
			stepperSusLength.value = curSelectedNote[2];
	}

	function updateGrid():Void {
		try {
			trace('ChartingState: Starting grid update');
			
			curRenderedBurning.clear();
			curRenderedNotes.clear();
			curRenderedSustains.clear();

			var currentSection = _song.notes[curSection];
			if (currentSection == null) {
				trace('ChartingState: ERROR - Current section is null!');
				return;
			}

			trace('ChartingState: Current section data: ' + Json.stringify(currentSection));

			var newBPM = currentSection.changeBPM && currentSection.bpm > 0 ? currentSection.bpm : _song.bpm;
			trace('ChartingState: Changing BPM to ${newBPM}');
			Conductor.changeBPM(newBPM);

			trace('ChartingState: Rendering main section notes');
			renderNotes(currentSection.sectionNotes);

			trace('ChartingState: Attempting to render next section');
			if (_song.notes[curSection + 1] != null) {
				renderNotes(_song.notes[curSection + 1].sectionNotes, GRID_SIZE * 16);
			}

			trace('ChartingState: Grid update complete');
			trace('ChartingState: Total notes rendered: ${curRenderedNotes.length}');
			trace('ChartingState: Total sustains rendered: ${curRenderedSustains.length}');
			trace('ChartingState: Total burning notes rendered: ${curRenderedBurning.length}');

		} catch(e:Dynamic) {
			trace('ChartingState: Error updating grid - ' + e);
			trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
			throw e;
		}
	}

    function renderNotes(sectionInfo:Array<Dynamic>, offset:Float = 0.0):Void {
		try {
			if (sectionInfo == null) return;

			for (noteData in sectionInfo) {
				var strumTime:Float = noteData[0];
				var noteType:Int = Std.int(noteData[1]) % 4; // Optimize modulo operation
				var sustain:Float = noteData[2] ?? 0;
				var isBurning:Bool = noteData[3] ?? false;

				var yPos = getYfromStrum(strumTime - sectionStartTime(), _song.notes[curSection].lengthInSteps) + offset;

				var note = new Note(strumTime, noteType, isBurning);
				note.sustainLength = sustain;
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.x = noteType * GRID_SIZE; // Remove unnecessary Math.floor
				note.y = yPos; // Remove unnecessary Math.floor

				if (isBurning) {
					note.color = FlxColor.RED;
					var burningEffect = new FlxSprite(note.x, note.y)
						.makeGraphic(GRID_SIZE, GRID_SIZE, FlxColor.RED);
					burningEffect.alpha = 0.5;
					curRenderedBurning.add(burningEffect);
				}

				curRenderedNotes.add(note);

				if (sustain > 0) {
					addSustainNote(note, noteType, sustain);
				}
			}
		} catch(e:Dynamic) {
			handleError("renderNotes", e);
		}
	}

	function addSustainNote(note:Note, daNoteInfo:Int, daSus:Float):Void {
    // Garantir que width seja um Int
    var sustainVis = new FlxSprite(note.x + GRID_SIZE / 2, note.y)
        .makeGraphic(8, // width já é Int literal
            Std.int(FlxMath.remapToRange(daSus, 0, Conductor.stepCrochet * 16, 0, gridBG.height)) + GRID_SIZE,
            note.burning ? FlxColor.RED : COLOR_LIST[daNoteInfo]); 
    curRenderedSustains.add(sustainVis);
}

	private function addSection(?lengthInSteps:Int):Void
	{
		if (lengthInSteps == null) lengthInSteps = DEFAULT_SECTION_LENGTH;
		
		try {
			var sec:SwagSection = {
				lengthInSteps: lengthInSteps,
				bpm: _song.bpm,
				changeBPM: false,
				mustHitSection: true,
				gfSection: false,
				sectionNotes: [],
				typeOfSection: 0,
				altAnim: false
			};

			_song.notes.push(sec);
		} catch(e:Dynamic) {
			handleError("addSection", e);
		}
	}


	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (i in _song.notes[curSection].sectionNotes)
		{
			if (i.strumTime == note.strumTime && i.noteData % 4 == note.noteData)
				curSelectedNote = _song.notes[curSection].sectionNotes[swagNum];

			swagNum += 1;
		}

		updateGrid();
		updateNoteUI();

		// Add selection effect
		var selectEffect = new FlxSprite(note.x - 2, note.y - 2)
			.makeGraphic(GRID_SIZE + 4, GRID_SIZE + 4, FlxColor.YELLOW);
		selectEffect.alpha = 0;
		add(selectEffect);

		FlxTween.tween(selectEffect, {alpha: 0.3}, 0.2, {
			ease: FlxEase.quartOut,
			type: PINGPONG
		});
	}

	function deleteNote(note:Note):Void {
		try {
			trace('ChartingState: Deleting note');
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
				{
					FlxG.log.add('FOUND EVIL NUMBER');
					_song.notes[curSection].sectionNotes.remove(i);
				}
			}

			updateGrid();

			// Add deletion effect
			var deleteEffect = new FlxSprite(note.x, note.y)
				.makeGraphic(GRID_SIZE, GRID_SIZE, FlxColor.RED); 
			deleteEffect.alpha = 0.4;
			add(deleteEffect);

			FlxTween.tween(deleteEffect, {alpha: 0, "scale.x": 1.5, "scale.y": 1.5}, 0.3, {
				ease: FlxEase.quartOut,
				onComplete: function(twn:FlxTween) {
					deleteEffect.destroy();
				}
			});
			trace('ChartingState: Finished deleting note');
		} catch(e:Dynamic) {
			trace('ChartingState: Error deleting note - ' + e);
			throw e;
		}
	}

	function clearSection():Void
	{
		_song.notes[curSection].sectionNotes = [];

		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	function addNote():Void {
		try {
			trace('ChartingState: Adding new note');
			var noteStrum = getStrumTime(dummyArrow.y) + (curSection * (Conductor.stepCrochet * 16));
			noteStrum = Math.floor(noteStrum / (Conductor.stepCrochet / (snapValues[curSnapIndex] / 4))) * (Conductor.stepCrochet / (snapValues[curSnapIndex] / 4));
			var noteData = Math.floor((FlxG.mouse.x - gridBG.x) / GRID_SIZE);

			if (noteData < 0 || noteData > 7) return;

			saveToUndo();

			var noteSus = 0;
			var isBurnNote = FlxG.keys.pressed.ALT;

			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, isBurnNote]);
			curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];

			if (FlxG.keys.pressed.CONTROL) {
				_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + 4) % 8, noteSus, isBurnNote]);
			}

			if (mirrorMode) {
				var oppositeData = 7 - noteData;
				_song.notes[curSection].sectionNotes.push([noteStrum, oppositeData, noteSus, isBurnNote]);
			}

			updateGrid();
			updateNoteUI();

			restartMusic(noteStrum);

			// Add visual feedback
			var noteVisual = new FlxSprite(dummyArrow.x, dummyArrow.y)
				.makeGraphic(GRID_SIZE, GRID_SIZE, FlxColor.LIME);
			noteVisual.alpha = 0.5;
			add(noteVisual);

			// Scale effect
			noteVisual.scale.set(1.2, 1.2);
			FlxTween.tween(noteVisual.scale, {x: 1, y: 1}, 0.2, {
				ease: FlxEase.quartOut,
				onComplete: function(twn:FlxTween) {
					FlxTween.tween(noteVisual, {alpha: 0}, 0.2, {
						onComplete: function(twn:FlxTween) {
							noteVisual.destroy();
						}
					});
				}
			});
			trace('ChartingState: Finished adding note');
		} catch(e:Dynamic) {
			trace('ChartingState: Error adding note - ' + e);
			throw e;
		}
	}

	inline function restartMusic(time:Float):Void {
        if (!FlxG.sound.music.playing) return;

        FlxG.sound.music.stop();
        vocals?.stop();
        FlxG.sound.music.time = time;
        vocals.time = time;
        FlxG.sound.music.play();
        vocals?.play();
    }

	function swaptheSection()
	{
		for (i in 0..._song.notes[curSection].sectionNotes.length)
		{
			var note = _song.notes[curSection].sectionNotes[i];
			note[1] = (note[1] + 4) % 8;
			_song.notes[curSection].sectionNotes[i] = note;
			updateGrid();
		}
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, sectionLength:Int):Float {
    try {
        if (sectionLength <= 0) return gridBG.y;
        
        var value = FlxMath.remapToRange(
            strumTime % (Conductor.stepCrochet * sectionLength), 
            0, 
            Conductor.stepCrochet * sectionLength, 
            gridBG.y, 
            gridBG.y + gridBG.height
        );
        
        return Math.isNaN(value) ? gridBG.y : value;
    } catch(e) {
        trace('Error in getYfromStrum: $e');
        return gridBG.y;
    }
}

	private var daSpacing:Float = 0.3;

	function loadLevel():Void
	{
		trace(_song.notes);
	}

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(song:String):Void
	{
		try {
			trace('ChartingState: Loading JSON for song ${song}');
			PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			trace('ChartingState: Successfully loaded JSON, resetting state');
			FlxG.resetState();
		} catch(e:Dynamic) {
			trace('ChartingState: Error loading JSON - ' + e);
			throw e;
		}
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseAndAdjustNoteData(FlxG.save.data.autosave);
		FlxG.resetState();
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel()
	{
		try {
			trace('ChartingState: Starting save level');
			var json = {
				"song": _song
			};

			var data:String = Json.stringify(json);

			if ((data != null) && (data.length > 0))
			{
				_file = new FileReference();
				_file.addEventListener(Event.COMPLETE, onSaveComplete);
				_file.addEventListener(Event.CANCEL, onSaveCancel);
				_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
				_file.save(data.trim(), _song.song.toLowerCase() + ".json");
			}
			trace('ChartingState: Finished saving level'); 
		} catch(e:Dynamic) {
			trace('ChartingState: Error saving level - ' + e);
			throw e;
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	function undoLastAction()
	{
		if (undoStack.length > 0)
		{
			var lastSection = undoStack.pop();
			redoStack.push(_song.notes[curSection]);
			_song.notes[curSection] = lastSection;
			updateGrid();
		}
		undoStack.push(copySwagSection(_song.notes[curSection]));
	}

	function redoLastAction()
	{
		if (redoStack.length > 0)
		{
			var nextSection = redoStack.pop();
			undoStack.push(_song.notes[curSection]);
			_song.notes[curSection] = nextSection;
			updateGrid();
		}
	}

	function saveToUndo()
	{
		undoStack.push(copySwagSection(_song.notes[curSection]));
		if (undoStack.length > MAX_UNDO_STACK_SIZE)
			undoStack.shift();
		FlxG.save.data.sectionBackups = undoStack;
	}


	function copyNotes()
	{
		copiedNotes = [];
		var minTime:Float = Math.POSITIVE_INFINITY;

		for (note in draggedNotes)
		{
			minTime = Math.min(minTime, note.strumTime);
		}

		for (note in draggedNotes)
		{
			var noteCopy:Array<Dynamic> = [
				note.strumTime - minTime, // Make positions relative
				note.noteData,
				note.sustainLength,
				note.burning
			];
			copiedNotes.push(noteCopy);
		}
	}

	function pasteNotes()
	{
		saveToUndo();
		var pasteTime = getStrumTime(FlxG.mouse.y);

		for (note in copiedNotes)
		{
			var strum = note[0] + pasteTime;
			_song.notes[curSection].sectionNotes.push([strum, note[1], note[2], note[3]]);
		}

		updateGrid();
	}

	function deleteNotes()
	{
		saveToUndo();
		for (note in draggedNotes)
		{
			deleteNote(note);
		}
		draggedNotes = [];
	}

	function nudgeNotes(xOffset:Float, yOffset:Float)
	{
		saveToUndo();
		for (note in draggedNotes)
		{
			var newX = note.x + xOffset;
			var newY = note.y + yOffset;

			// Update note data
			var noteData = Math.floor((newX - gridBG.x) / GRID_SIZE);
			var strumTime = getStrumTime(newY);

			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] % 4 == note.noteData)
				{
					i[0] = strumTime;
					i[1] = noteData;
				}
			}
		}
		updateGrid();
	}

	function duplicateNotes()
	{
		saveToUndo();
		var offset = Conductor.stepCrochet * 4;
		for (note in draggedNotes)
		{
			var newNote = new Note(note.strumTime, note.noteData, note.burning);
			newNote.sustainLength = note.sustainLength;
			newNote.strumTime += offset;
			_song.notes[curSection].sectionNotes.push([newNote.strumTime, newNote.noteData, newNote.sustainLength, newNote.burning]);
		}
		updateGrid();
	}

	function selectAllNotes()
	{
		draggedNotes = [];
		curRenderedNotes.forEach(function(note:Note)
		{
			note.alpha = 0.5;
			draggedNotes.push(note);
		});
	}

	private function loadAvailableCharacters():Array<String> {
		try {
			trace('ChartingState: Loading available characters');
			var chars:Array<String> = [];
			var charactersPath = "assets/preload/data/characters/";
			
			if (FileSystem.exists(charactersPath)) {
				for (file in FileSystem.readDirectory(charactersPath)) {
					if (file.endsWith(".json")) {
						var charName = file.substring(0, file.length - 5);
						chars.push(charName);
					}
				}
			}

			if (ModManager.activeMods != null) {
				for (mod in ModManager.activeMods) {
					var modCharPath = mod.path + "characters/";
					if (FileSystem.exists(modCharPath)) {
						for (file in FileSystem.readDirectory(modCharPath)) {
							if (file.endsWith(".json")) {
								var charName = file.substring(0, file.length - 5);
								if (!chars.contains(charName)) chars.push(charName);
							}
							}
						}
					}
				}

			chars.sort((a, b) -> a.toLowerCase() > b.toLowerCase() ? 1 : -1);
			trace('ChartingState: Found ${chars.length} characters');
			return chars.length > 0 ? chars : CoolUtil.coolTextFile(Paths.txt('characterList'));
		} catch(e:Dynamic) {
			trace('ChartingState: Error loading characters - ' + e);
			throw e;
		}
	}

    private function showToast(message:String, color:FlxColor = FlxColor.WHITE) {
        var toast = UIEffects.showToast(message, color);
        add(toast);
    }

    private function createEffect(success:Bool, x:Float, y:Float) {
        var effects = UIEffects.createStatusEffect(success, x, y);
        for (effect in effects)
            add(effect);
    }

	private function handleError(functionName:String, error:Dynamic):Void {
		trace('ChartingState: Error in $functionName - $error');
		trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
		
		throw error;
	}

	function addMarker(time:Float, name:String) {
		markers.set(time, name);
		updateMarkerVisuals();
		showToast('Added marker: $name', FlxColor.LIME);
	}

	function removeMarker(time:Float) {
		if (markers.exists(time)) {
			var name = markers.get(time);
			markers.remove(time);
			updateMarkerVisuals();
			showToast('Removed marker: $name', FlxColor.RED);
		}
	}

	function updateMarkerVisuals() {
		markerTexts.clear();
		for (time in markers.keys()) {
			var text = new FlxText(gridBG.x - 100, getYfromStrum(time, _song.notes[curSection].lengthInSteps), 95);
			text.alignment = RIGHT;
			text.text = markers.get(time);
			text.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE);
			markerTexts.add(text);
		}
	}

	function showHelpText(text:String, x:Float, y:Float) {
		helpTxt.text = text;
		helpTxt.x = x;
		helpTxt.y = y;
		helpTxt.visible = true;
		
		if (helpTxt.x + helpTxt.width > FlxG.width)
			helpTxt.x = FlxG.width - helpTxt.width;
	}

	function hideHelpText() {
		helpTxt.visible = false;
	}

	function setZoom(zoom:Float) {
		currentZoom = zoom;
		GRID_SIZE = Std.int(GRID_SIZE_BASE * zoom);
		updateGrid();
		showToast('Zoom: ${Math.floor(zoom * 100)}%');
	}

	override function destroy() {
		cleanupResources();
		super.destroy();
	}

	private function cleanupResources():Void {
		// Limpar grupos de sprites
		if (curRenderedNotes != null) {
			curRenderedNotes.destroy();
			curRenderedNotes = null;
		}
		if (curRenderedSustains != null) {
			curRenderedSustains.destroy();
			curRenderedSustains = null;
		}
		if (curRenderedBurning != null) {
			curRenderedBurning.destroy();
			curRenderedBurning = null;
		}
		
		// Limpar audio
		cleanupAudio();
		
		// Limpar UI
		if (UI_box != null) {
			UI_box.destroy();
			UI_box = null;
		}
		
		// Limpar timers
		if (autoSaveTimer != null) {
			autoSaveTimer.cancel();
			autoSaveTimer = null;
		}
	}

	private function safeTween(object:Dynamic, values:Dynamic, duration:Float, ?options:Dynamic):FlxTween {
		try {
			return FlxTween.tween(object, values, duration, options);
		} catch(e) {
			trace('Error creating tween: $e');
			return null;
		}
	}

	private function createTweenWithCleanup(object:Dynamic, values:Dynamic, duration:Float, 
		?options:Dynamic):FlxTween {
		if (object == null) return null;
		
		var tween = FlxTween.tween(object, values, duration, options);
		if (tween != null) {
			tween.onComplete = function(twn:FlxTween) {
				twn.destroy();
				if (options != null && options.onComplete != null)
					options.onComplete(twn);
			}
		}
		return tween;
	}

	private function handleControlInputs():Void {
		if (FlxG.keys.justPressed.Z && undoStack.length > 0)
			undoLastAction();
			
		if (FlxG.keys.justPressed.Y && redoStack.length > 0)
			redoLastAction();
			
		if (FlxG.keys.justPressed.S)
			autosaveSong();
			
		if (FlxG.keys.justPressed.C && draggedNotes.length > 0)
			copyNotes();
			
		if (FlxG.keys.justPressed.V && copiedNotes.length > 0)
			pasteNotes();
	}

	private function handleAltInputs():Void {
		var xOffset:Float = 0;
		var yOffset:Float = 0;

		if (FlxG.keys.pressed.LEFT) xOffset = -GRID_SIZE;
		if (FlxG.keys.pressed.RIGHT) xOffset = GRID_SIZE;
		if (FlxG.keys.pressed.UP) yOffset = -GRID_SIZE;
		if (FlxG.keys.pressed.DOWN) yOffset = GRID_SIZE;

		if (xOffset != 0 || yOffset != 0)
			nudgeNotes(xOffset, yOffset);
	}
}
