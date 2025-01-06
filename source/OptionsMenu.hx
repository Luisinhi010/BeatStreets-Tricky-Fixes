package;

import Options;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsMenu extends MusicBeatState
{
	var selector:FlxText;
	var curSelected:Int = 0;

	var options:Array<OptionCatagory> = [
		new OptionCatagory("Gameplay", [
			new DFJKOption(controls),
			new LowEnd("low end mode for low end users"),
			new GhostTapOption("Ghost Tapping is when you tap a direction and it doesn't give you a miss."),
			#if desktop //
			new FPSCapOption("Cap your FPS (Left for -10, Right for +10. SHIFT to go faster)"), #end //
			new ScrollSpeedOption("Change your scroll speed (Left for -0.1, right for +0.1. If it's at 1, it will be chart dependent)"),
			new AccuracyDOption("Change how accuracy is calculated. (Accurate = Simple, Complex = Milisecond Based)"),
		]),
		new OptionCatagory("Appearance", [
			new AccuracyOption("Display accuracy information."),
			new DownscrollOption("Change the layout of the strumline."),
		]),
		new OptionCatagory("Misc", [new FPSOption("Toggle the FPS Counter")])
	];

	public var currentOptions:Array<FlxText> = [];

	var currentSelectedCat:OptionCatagory;
	var menuShade:FlxSprite;
	var offsetDisplay:FlxText;
	var isCategorySelected:Bool = false;

	var yperoption:Int = 70;
	var sizeperoption:Int = 25;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.y += 40;
		add(bg);
		var hedge:FlxSprite = new FlxSprite(-810, -335).loadGraphic(Paths.image('menu/freeplay/hedge', 'clown'));
		hedge.setGraphicSize(Std.int(hedge.width * 0.65));
		add(hedge);
		var shade:FlxSprite = new FlxSprite(-205, -100).loadGraphic(Paths.image('menu/freeplay/Shadescreen', 'clown'));
		shade.setGraphicSize(Std.int(shade.width * 0.65));
		add(shade);
		var bars:FlxSprite = new FlxSprite(-225, -395).loadGraphic(Paths.image('menu/freeplay/theBox', 'clown'));
		bars.setGraphicSize(Std.int(bars.width * 0.65));
		add(bars);

		for (i in 0...options.length)
		{
			var text:FlxText = new FlxText(125, (yperoption * i) + 100, 0, "", sizeperoption);
			text.color = FlxColor.fromRGB(0, 255, 255);
			text.setFormat("tahoma-bold.ttf", 60, FlxColor.CYAN);
			add(text);
			currentOptions.push(text);
		}

		updateDisplay();

		offsetDisplay = new FlxText(125, 600, 0, "Offset: " + FlxG.save.data.offset);
		offsetDisplay.setFormat("tahoma-bold.ttf", 42, FlxColor.CYAN);
		add(offsetDisplay);

		menuShade = new FlxSprite(-1350, -1190).loadGraphic(Paths.image("menu/freeplay/Menu Shade", 'clown'));
		menuShade.setGraphicSize(Std.int(menuShade.width * 0.7));
		add(menuShade);

		super.create();
	}

	function updateDisplay()
		{
			var displayOptions:Array<Dynamic> = isCategorySelected ? currentSelectedCat.getOptions() : options;
			var prevSelected:Int = curSelected; // Store previously selected index
	
			for (i in 0...displayOptions.length)
			{
				var option:Dynamic = displayOptions[i];
				var text:FlxText = currentOptions[i];
				text.text = option.getName() != null ? option.getName() : option.getDisplay();
	
				if (i == curSelected) {
					text.color = FlxColor.WHITE;
				} else if (i == prevSelected && i != curSelected) {
					text.color = FlxColor.CYAN;
				}
			}
		}

	function adjustOffset(amount:Int)
	{
		FlxG.save.data.offset += amount;
		offsetDisplay.text = "Offset: " + FlxG.save.data.offset + " (Left/Right)";
	}

	var isCat:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time;

		if (controls.BACK && !isCategorySelected)
			FlxG.switchState(new MainMenuState());
		else if (controls.BACK)
		{
			isCategorySelected = false;
			curSelected = 0;
			updateDisplay();
		}

		if (FlxG.keys.justPressed.UP)
			changeSelection(-1);
		if (FlxG.keys.justPressed.DOWN)
			changeSelection(1);

		var offsetChange:Int = 0;
		if (FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.pressed.RIGHT)
				offsetChange = 1;
			if (FlxG.keys.pressed.LEFT)
				offsetChange = -1;
		}
		else
		{
			if (FlxG.keys.justPressed.RIGHT)
				offsetChange = 1;
			if (FlxG.keys.justPressed.LEFT)
				offsetChange = -1;
		}

		if (offsetChange != 0)
			adjustOffset(offsetChange);

		if (controls.RESET)
			FlxG.save.data.offset = 0;

		if (controls.ACCEPT)
		{
			FlxG.sound.play(Paths.sound("confirm", 'clown'));
			if (isCategorySelected)
			{
				if (currentSelectedCat.getOptions()[curSelected].press())
				{
					updateDisplay();
				}
			}
			else
			{
				currentSelectedCat = options[curSelected];
				isCategorySelected = true;
				curSelected = 0;
				updateDisplay();
			}
		}
		FlxG.save.flush();
	}

	var isSettingControl:Bool = false;

	function changeSelection(change:Int = 0)
		{
			FlxG.sound.play(Paths.sound("Hover", 'clown'));
	
			var prevSelected:Int = curSelected;
	
			curSelected += change;
	
			if (curSelected < 0)
				curSelected = currentOptions.length - 1;
			if (curSelected >= currentOptions.length)
				curSelected = 0;
	
			currentOptions[prevSelected].color = FlxColor.CYAN;
			currentOptions[curSelected].color = FlxColor.WHITE;
		}
}
