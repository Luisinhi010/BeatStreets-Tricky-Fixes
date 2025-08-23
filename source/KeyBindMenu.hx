package;

import ui.MenuControls;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class KeyBindMenu extends MusicBeatState
{
	var keyTextDisplay:FlxText;
	var keyWarning:FlxText;
	var warningTween:FlxTween;
	var keyText:Array<String> = ["LEFT", "DOWN", "UP", "RIGHT"];
	var defaultKeys:Array<String> = ["A", "S", "W", "D", "R"];
	var curSelected:Int = 0;

	var keys:Array<String> = [
		FlxG.save.data.leftBind,
		FlxG.save.data.downBind,
		FlxG.save.data.upBind,
		FlxG.save.data.rightBind
	];

	var gamepadKeys:Map<Control, Array<FlxGamepadInputID>>;

	var tempKey:String = "";
	var blacklist:Array<String> = ["ESCAPE", "ENTER", "BACKSPACE", "SPACE"];

	var state:String = "select";
	var bindingDevice:Device = Keys;
	var containerWidth:Float = 1690;
	var containerHeight:Float = 890;
	var optionSpacing:Float = 60;
	var keyTexts:Array<FlxText> = [];

	override function create()
	{
		for (i in 0...keys.length)
			if (keys[i] == null)
				keys[i] = defaultKeys[i];

		if (FlxG.save.data.gamepadBinds != null)
			gamepadKeys = FlxG.save.data.gamepadBinds;
		else
			gamepadKeys = new Map<Control, Array<FlxGamepadInputID>>();

		persistentUpdate = persistentDraw = true;

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

		var startY:Float = (FlxG.height - (keyText.length * optionSpacing)) / 2;

		for (i in 0...keyText.length)
		{
			var text = new FlxText(0, startY + (optionSpacing * i), FlxG.width);
			text.setFormat("tahoma-bold.ttf", 38, FlxColor.CYAN, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 2;
			text.borderQuality = 1;
			add(text);
			keyTexts.push(text);
		}

		keyWarning = new FlxText(0, 580, FlxG.width, "WARNING: BIND NOT SET, TRY ANOTHER KEY", 42);
		keyWarning.setFormat("tahoma-bold.ttf", 42, FlxColor.CYAN, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyWarning.borderSize = 3;
		keyWarning.borderQuality = 1;
		keyWarning.screenCenter(X);
		keyWarning.alpha = 0;
		add(keyWarning);

		warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0);

		updateTexts();
		super.create();
	}

	function updateTexts()
	{
		for (i in 0...keyText.length)
		{
			var text = keyTexts[i];
			text.color = (i == curSelected) ? FlxColor.WHITE : FlxColor.CYAN;

			var gamepadBindText = "";
			var control = getControl();
			if (control != null && gamepadKeys.exists(control))
			{
				var gamepadBinds = gamepadKeys.get(control);
				if (gamepadBinds != null && gamepadBinds.length > 0)
				{
					gamepadBindText = " / ";
					for (j in 0...gamepadBinds.length)
					{
						gamepadBindText += gamepadBinds[j].toString();
						if (j < gamepadBinds.length - 1)
							gamepadBindText += ", ";
					}
				}
			}

			text.text = keyText[i] + ": " + ((keys[i] != keyText[i]) ? (keys[i] + " / ") : "") + keyText[i] + " ARROW" + gamepadBindText;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (state)
		{
			case "select":
				handleSelectState();
			case "input":
				handleInputState();
			case "waiting":
				handleWaitingState();
		}

		if (FlxG.keys.justPressed.ANY)
			updateTexts();
	}

	function handleSelectState()
	{
		var prevSelected = curSelected;
		curSelected = MenuControls.handleMenuInput(this, curSelected, keyText.length, function()
		{
			state = "input";
		}, function()
		{
			save();
			FlxG.switchState(new OptionsMenu());
		});

		if (prevSelected != curSelected)
			updateTexts();

		if (FlxG.keys.justPressed.LEFT)
		{
			bindingDevice = Keys;
			updateTexts();
		}
		else if (FlxG.keys.justPressed.RIGHT)
		{
			bindingDevice = Gamepad(0); // Assuming first gamepad
			updateTexts();
		}

		if (FlxG.keys.justPressed.R)
			reset();
	}

	function handleInputState()
	{
		tempKey = keys[curSelected];
		keys[curSelected] = "?";
		updateTexts();
		state = "waiting";
	}

	function handleWaitingState()
	{
		if (FlxG.keys.justPressed.ESCAPE)
		{
			keys[curSelected] = tempKey;
			state = "select";
			FlxG.sound.play(Paths.sound('confirm', 'clown'));
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			addKey(defaultKeys[curSelected]);
			save();
			state = "select";
		}
		else if (bindingDevice == Keys && FlxG.keys.justPressed.ANY)
		{
			var pressedKey = FlxG.keys.getIsDown()[0].ID.toString();
			if (!blacklist.contains(pressedKey))
			{
				addKey(pressedKey);
				save();
				state = "select";
			}
			else
			{
				keys[curSelected] = tempKey;
				showWarning();
				state = "select";
			}
		}
		else if (bindingDevice == Gamepad(0) && FlxG.gamepads.anyJustPressed(FlxInputDeviceID.ANY) != FlxGamepadInputID.INVALID)
		{
			var pressedButton = FlxG.gamepads.anyJustPressed(FlxInputDeviceID.ANY);
			addGamepadBind(pressedButton);
			save();
			state = "select";
		}
	}

	function addGamepadBind(button:FlxGamepadInputID)
	{
		var control = getControl();
		if (gamepadKeys.get(control) == null)
			gamepadKeys.set(control, []);

		// remove button if it's already bound to another control
		for (c in gamepadKeys.keys())
		{
			if (c != control)
			{
				gamepadKeys[c].remove(button);
			}
		}

		if (gamepadKeys[control].indexOf(button) == -1)
			gamepadKeys[control].push(button);

		FlxG.sound.play(Paths.sound('Hover', 'clown'));
	}

	function getControl():Control
	{
		return switch (curSelected)
		{
			case 0: LEFT;
			case 1: DOWN;
			case 2: UP;
			case 3: RIGHT;
			default: null;
		}
	}

	function showWarning()
	{
		warningTween.cancel();
		keyWarning.alpha = 1;
		warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0.5, {
			ease: FlxEase.circOut,
			startDelay: 2
		});
	}

	function save()
	{
		FlxG.save.data.upBind = keys[2];
		FlxG.save.data.downBind = keys[1];
		FlxG.save.data.leftBind = keys[0];
		FlxG.save.data.rightBind = keys[3];
		FlxG.save.data.gamepadBinds = gamepadKeys;

		FlxG.save.flush();

		PlayerSettings.player1.controls.loadKeyBinds();
		PlayerSettings.player1.controls.loadGamepadBinds(FlxInputDeviceID.ANY);
	}

	function reset()
	{
		for (i in 0...5)
		{
			keys[i] = defaultKeys[i];
		}
		gamepadKeys.clear();
		quit();
	}

	function quit()
	{
		state = "exiting";

		save();

		FlxG.switchState(new OptionsMenu());
	}

	function addKey(r:String)
	{
		var shouldReturn:Bool = true;

		var notAllowed:Array<String> = [];

		for (x in keys)
		{
			if (x != tempKey)
			{
				notAllowed.push(x);
			}
		}

		for (x in blacklist)
		{
			notAllowed.push(x);
		}

		if (curSelected != 4)
		{
			for (x in keyText)
			{
				if (x != keyText[curSelected])
				{
					notAllowed.push(x);
				}
			}
		}
		else
		{
			for (x in keyText)
			{
				notAllowed.push(x);
			}
		}

		trace(notAllowed);

		for (x in 0...keys.length)
		{
			var oK = keys[x];
			if (oK == r)
				keys[x] = null;
		}

		if (shouldReturn)
		{
			keys[curSelected] = r;
			FlxG.sound.play(Paths.sound('Hover', 'clown'));
		}
		else
		{
			keys[curSelected] = tempKey;
			FlxG.sound.play(Paths.sound('confirm', 'clown'));
			keyWarning.alpha = 1;
			warningTween.cancel();
			warningTween = FlxTween.tween(keyWarning, {alpha: 0}, 0.5, {ease: FlxEase.circOut, startDelay: 2});
		}
	}

	function changeItem(_amount:Int = 0)
	{
		curSelected += _amount;

		if (curSelected > 3)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = 3;
	}
}
