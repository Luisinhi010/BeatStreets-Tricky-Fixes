package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class MenuControls
{
	static var newSelected:Int = 0;
	public static var usingKeyboard:Bool = false;

	public static function handleMenuInput(state:MusicBeatState, curSelected:Int, maxItems:Int, onSelect:Void->Void, ?onBack:Void->Void):Int
	{
		var newSelected = curSelected;
		if (usingKeyboard)
		{
			if (FlxG.keys.justPressed.UP || state.controls.UP_P)
			{
				newSelected--;
				if (newSelected < 0)
					newSelected = maxItems - 1;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (FlxG.keys.justPressed.DOWN || state.controls.DOWN_P)
			{
				newSelected++;
				if (newSelected >= maxItems)
					newSelected = 0;
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (FlxG.keys.justPressed.ENTER || state.controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				onSelect();
			}

			if ((FlxG.keys.justPressed.ESCAPE || state.controls.BACK) && onBack != null)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				onBack();
			}
		}
		else
		{
			if (FlxG.mouse.wheel != 0)
			{
				newSelected -= FlxG.mouse.wheel;
				if (newSelected < 0)
					newSelected = maxItems - 1;
				else if (newSelected >= maxItems)
					newSelected = 0;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				usingKeyboard = false;
			}

			if (FlxG.mouse.justPressed)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				onSelect();
			}

			if ((FlxG.keys.justPressed.ESCAPE || state.controls.BACK) && onBack != null)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				onBack();
				usingKeyboard = true;
			}
		}
		return newSelected;
	}
}
