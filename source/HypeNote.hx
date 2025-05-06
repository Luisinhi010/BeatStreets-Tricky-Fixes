package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;

class HypeNote extends CustomSprite // from: https://gamebanana.com/mods/546439
{
	public function new(x:Float, y:Float, direction:Int)
	{
		super(x, y);
		enable3D = false;

		loadGraphic(Paths.image('customnotes/HypeNote', 'shared'));
		antialiasing = !FlxG.save.data.lowend;

		switch (direction)
		{
			case 0:
				angle = 0;
				color = 0xFF3636;
			case 1:
				angle = 270;
				color = 0xA745FF;
			case 2:
				angle = 90;
				color = 0x0AE4AE;
			case 3:
				angle = 180;
				color = 0x9DFF55;
		}

		scale.set(0.3, 0.7);
		FlxTween.tween(scale, {x: 1.2, y: 1.2}, 0.4, {ease: FlxEase.quartOut});

		alpha = 1;
		FlxTween.tween(this, {alpha: 0}, 0.4, {
			onComplete: function(twn:FlxTween)
			{
				destroy();
			}
		});
	}
}
