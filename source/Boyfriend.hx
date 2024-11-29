package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;

using StringTools;

class Boyfriend extends Character
{
	public var stunned:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
		if (!debugMode)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			else
				holdTimer = 0;

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
				playAnim('idle', true, false, 10);

			if (curCharacter == 'Alldeath' && animation.curAnim.name != 'deathConfirm' && animation.curAnim.finished)
				playAnim('deathLoop');
		}

		super.update(elapsed);
	}

	// nya~
	override function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		if (curCharacter == 'bf')
		{
			if (AnimName.endsWith('miss'))
				this.color = FlxColor.CYAN;
			else
				this.color = FlxColor.WHITE;
		}

		super.playAnim(AnimName, Force, Reversed, Frame);
	}
}
