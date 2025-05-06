package;

import flixel.addons.ui.FlxUITypedButton;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.FlxSprite;
import flixel.text.FlxText;

class ExtendedFlxUINumericStepper extends FlxUINumericStepper
{
	public var onChange:Dynamic->Void;

	public function new(X:Float = 0, Y:Float = 0, StepSize:Float = 1, DefaultValue:Float = 0, Min:Float = -999, Max:Float = 999, Decimals:Int = 0,
			Stack:Int = FlxUINumericStepper.STACK_HORIZONTAL, ?TextField:FlxText, ?ButtonPlus:FlxUITypedButton<FlxSprite>,
			?ButtonMinus:FlxUITypedButton<FlxSprite>, IsPercent:Bool = false)
	{
		super(X, Y, StepSize, DefaultValue, Min, Max, Decimals, Stack, TextField, ButtonPlus, ButtonMinus, IsPercent);
	}

	override private function _onInputTextEvent(text:String, action:String):Void
	{
		super._onInputTextEvent(text, action);
		if (onChange != null)
			onChange(value);
	}

	override private function _onPlus():Void
	{
		super._onPlus();
		if (onChange != null)
			onChange(value);
	}

	override private function _onMinus():Void
	{
		super._onMinus();
		if (onChange != null)
			onChange(value);
	}
}
