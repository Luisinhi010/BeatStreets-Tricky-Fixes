package ui;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import Controls;
import PlayerSettings;

class InputDisplay extends FlxSpriteGroup
{
	private var keyboardText:FlxText;
	private var gamepadText:FlxText;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		keyboardText = new FlxText(0, 0, 0, "", 12);
		keyboardText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(keyboardText);

		gamepadText = new FlxText(0, 150, 0, "", 12);
		gamepadText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(gamepadText);

		refresh();
	}

	public function refresh()
	{
		var controls = PlayerSettings.player1.controls;
		if (controls == null)
			return;

		// Keyboard
		var up = controls.getInputsFor(Control.UP, Keys);
		var down = controls.getInputsFor(Control.DOWN, Keys);
		var left = controls.getInputsFor(Control.LEFT, Keys);
		var right = controls.getInputsFor(Control.RIGHT, Keys);
		var accept = controls.getInputsFor(Control.ACCEPT, Keys);
		var back = controls.getInputsFor(Control.BACK, Keys);

		keyboardText.text = "Keyboard:\n";
		keyboardText.text += "Up: " + getKeyName(up) + "\n";
		keyboardText.text += "Down: " + getKeyName(down) + "\n";
		keyboardText.text += "Left: " + getKeyName(left) + "\n";
		keyboardText.text += "Right: " + getKeyName(right) + "\n";
		keyboardText.text += "Accept: " + getKeyName(accept) + "\n";
		keyboardText.text += "Back: " + getKeyName(back) + "\n";

		// Gamepad
		var gamepadUp = controls.getInputsFor(Control.UP, Gamepad(0));
		var gamepadDown = controls.getInputsFor(Control.DOWN, Gamepad(0));
		var gamepadLeft = controls.getInputsFor(Control.LEFT, Gamepad(0));
		var gamepadRight = controls.getInputsFor(Control.RIGHT, Gamepad(0));
		var gamepadAccept = controls.getInputsFor(Control.ACCEPT, Gamepad(0));
		var gamepadBack = controls.getInputsFor(Control.BACK, Gamepad(0));

		gamepadText.text = "Gamepad:\n";
		gamepadText.text += "Up: " + getGamepadButtonName(gamepadUp) + "\n";
		gamepadText.text += "Down: " + getGamepadButtonName(gamepadDown) + "\n";
		gamepadText.text += "Left: " + getGamepadButtonName(gamepadLeft) + "\n";
		gamepadText.text += "Right: " + getGamepadButtonName(gamepadRight) + "\n";
		gamepadText.text += "Accept: " + getGamepadButtonName(gamepadAccept) + "\n";
		gamepadText.text += "Back: " + getGamepadButtonName(gamepadBack) + "\n";
	}

	private function getKeyName(keys:Array<Int>):String
	{
		if (keys == null || keys.length == 0)
			return "N/A";

		var result = [];
		for (key in keys)
		{
			var flxKey:FlxKey = key;
			result.push(Std.string(flxKey));
		}
		return result.join(", ");
	}

	private function getGamepadButtonName(buttons:Array<Int>):String
	{
		if (buttons == null || buttons.length == 0)
			return "N/A";

		var result = [];
		for (button in buttons)
		{
			var gamepadButton:FlxGamepadInputID = button;
			result.push(Std.string(gamepadButton));
		}
		return result.join(", ");
	}
}
