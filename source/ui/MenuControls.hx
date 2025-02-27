package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class MenuControls
{
	public static function handleMenuInput(state:MusicBeatState, curSelected:Int, maxItems:Int, onSelect:Void->Void, ?onBack:Void->Void):Int
	{
		var newSelected = curSelected;

		if (FlxG.keys.justPressed.UP || state.get_controls().UP_P)
		{
			FlxG.sound.play(Paths.sound('Hover', 'clown'));
			newSelected--;
			if (newSelected < 0)
				newSelected = maxItems - 1;
		}

		if (FlxG.keys.justPressed.DOWN || state.get_controls().DOWN_P)
		{
			FlxG.sound.play(Paths.sound('Hover', 'clown'));
			newSelected++;
			if (newSelected >= maxItems)
				newSelected = 0;
		}

		if (FlxG.keys.justPressed.ENTER || state.get_controls().ACCEPT)
		{
			FlxG.sound.play(Paths.sound('confirm', 'clown'));
			onSelect();
		}

		if ((FlxG.keys.justPressed.ESCAPE || state.get_controls().BACK) && onBack != null)
		{
			FlxG.sound.play(Paths.sound('Hover', 'clown'));
			onBack();
		}

		return newSelected;
	}
}
