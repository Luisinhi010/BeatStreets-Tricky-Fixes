package;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import Options;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.MenuControls;

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
	var selectedSmth:Bool = false;

	var yperoption:Int = 70;
	var sizeperoption:Int = 25;

	var containerWidth:Float = 1690;
	var containerHeight:Float = 890;
	var optionSpacing:Float = 60;

	var lastCategorySelected:Int = 0;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.y += 40;
		add(bg);
		var mist = new VolumetricCloudSprite(0, 0);
		mist.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		mist.cloudType = MIST;
		mist.setColors(0xFF545FC4, 0xFFCACAFA);
		mist.blend = ADD;
		add(mist);
		var hedge:FlxSprite = new FlxSprite(-810, -335).loadGraphic(Paths.image('menu/freeplay/hedge', 'clown'));
		hedge.setGraphicSize(Std.int(hedge.width * 0.65));
		add(hedge);
		var shade:FlxSprite = new FlxSprite(-205, -100).loadGraphic(Paths.image('menu/freeplay/Shadescreen', 'clown'));
		shade.setGraphicSize(Std.int(shade.width * 0.65));
		add(shade);
		var bars:FlxSprite = new FlxSprite(-225, -395).loadGraphic(Paths.image('menu/freeplay/theBox', 'clown'));
		bars.setGraphicSize(Std.int(bars.width * 0.65));
		add(bars);

		var startY:Float = (FlxG.height - (options.length * optionSpacing)) / 2;
		var startX:Float = (FlxG.width - containerWidth) / 2 + 100;

		var maxOptions:Int = 0;
		for (category in options)
			maxOptions = Std.int(Math.max(maxOptions, category.getOptions().length));
		maxOptions = Std.int(Math.max(maxOptions, options.length));

		for (i in 0...maxOptions)
		{
			var text:FlxText = new FlxText(startX, startY + (optionSpacing * i), containerWidth - 200, "", sizeperoption);
			text.setFormat("tahoma-bold.ttf", 60, FlxColor.CYAN);
			text.alignment = CENTER;
			text.visible = false;
			add(text);
			currentOptions.push(text);

			text.alpha = 0;
			FlxTween.tween(text, {alpha: 1}, 0.3, {
				startDelay: i * 0.1,
				ease: FlxEase.quartOut
			});
		}

		updateDisplay();

		offsetDisplay = new FlxText(0, FlxG.height - 100, FlxG.width, "Offset: " + FlxG.save.data.offset);
		offsetDisplay.setFormat("tahoma-bold.ttf", 42, FlxColor.CYAN);
		offsetDisplay.alignment = CENTER;
		add(offsetDisplay);

		menuShade = new FlxSprite(-1350, -1190).loadGraphic(Paths.image("menu/freeplay/Menu Shade", 'clown'));
		menuShade.setGraphicSize(Std.int(menuShade.width * 0.7));
		add(menuShade);

		super.create();
	}

	function updateDisplay()
	{
		var displayOptions:Array<Dynamic> = isCategorySelected ? currentSelectedCat.getOptions() : options;
		var startY:Float = (FlxG.height - (displayOptions.length * optionSpacing)) / 2;

		for (text in currentOptions)
			text.visible = false;

		for (i in 0...displayOptions.length)
		{
			var text:FlxText;

			if (i >= currentOptions.length)
			{
				text = new FlxText(0, startY + (optionSpacing * i), FlxG.width);
				text.setFormat("tahoma-bold.ttf", 48, FlxColor.CYAN, CENTER);
				add(text);
				currentOptions.push(text);
			}
			else
			{
				text = currentOptions[i];
				text.visible = true;
				text.y = startY + (optionSpacing * i);
			}

			text.color = i == curSelected ? FlxColor.WHITE : FlxColor.CYAN;

			if (isCategorySelected)
				text.text = displayOptions[i].getDisplay();
			else
				text.text = displayOptions[i].getName();
		}

		for (i in displayOptions.length...currentOptions.length)
			currentOptions[i].visible = false;
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

		if (!selectedSmth)
		{
			if (!isCategorySelected)
			{
				var newSelected = MenuControls.handleMenuInput(this, curSelected, options.length, function()
				{
					isCategorySelected = true;
					currentSelectedCat = options[curSelected];
					lastCategorySelected = curSelected;
					curSelected = 0;
					updateDisplay();
				}, function()
				{
					FlxG.switchState(new MainMenuState());
				});

				if (newSelected != curSelected)
				{
					curSelected = newSelected;
					updateDisplay();
				}
			}
			else
			{
				var currentOption = currentSelectedCat.getOptions()[curSelected];
				var newSelected = MenuControls.handleMenuInput(this, curSelected, currentSelectedCat.getOptions().length, function()
				{
					if (currentOption.press())
						updateDisplay();
				}, function()
				{
					isCategorySelected = false;
					curSelected = lastCategorySelected;
					updateDisplay();
				});

				if (newSelected != curSelected)
				{
					curSelected = newSelected;
					updateDisplay();
				}

				if (!currentOption.getAccept())
				{
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
				}
				else
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						currentOption.right();
						updateDisplay();
					}
					else if (FlxG.keys.justPressed.LEFT)
					{
						currentOption.left();
						updateDisplay();
					}
				}

				if (controls.RESET)
					FlxG.save.data.offset = 0;
			}
		}

		FlxG.save.flush();
	}

	var isSettingControl:Bool = false;

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound("Hover", 'clown'));

		var prevSelected:Int = curSelected;
		var maxOptions:Int = isCategorySelected ? (currentSelectedCat != null
			&& currentSelectedCat.getOptions() != null ? currentSelectedCat.getOptions().length : 0) : options.length;

		curSelected += change;

		if (curSelected < 0)
			curSelected = maxOptions - 1;
		if (curSelected >= maxOptions)
			curSelected = 0;

		for (i in 0...currentOptions.length)
		{
			if (currentOptions[i] != null)
				currentOptions[i].color = (i == curSelected) ? FlxColor.WHITE : FlxColor.CYAN;
		}
	}
}
