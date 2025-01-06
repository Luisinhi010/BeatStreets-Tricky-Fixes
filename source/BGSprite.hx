package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.util.FlxDestroyUtil;
import Paths;

class BGSprite extends FlxSprite
{
	public var loopable:Bool = false;
	public var autoScroll:Bool = false;
	public var scrollSpeed:FlxPoint;

	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1.0, ?scrollY:Float = 1.0, ?loopable:Bool = false, ?autoScroll:Bool = false,
			?scrollSpeedX:Float = 0, ?scrollSpeedY:Float = 0)
	{
		super(x, y);
		loadGraphic(Paths.image(image));
		this.loopable = loopable;
		this.autoScroll = autoScroll;
		this.scrollSpeed = FlxPoint.get(scrollSpeedX, scrollSpeedY);
		antialiasing = !FlxG.save.data.lowend;
		scrollFactor.set(scrollX, scrollY);
		moves = active = autoScroll;
	}

	override function update(elapsed:Float)
	{
		if (autoScroll)
		{
			x += scrollSpeed.x * elapsed;
			y += scrollSpeed.y * elapsed;

			if (loopable)
			{
				if (x > FlxG.width)
					x = -width;
				if (x < -width)
					x = FlxG.width;
				if (y > FlxG.height)
					y = -height;
				if (y < -height)
					y = FlxG.height;
			}
		}
		super.update(elapsed);
	}

	override function destroy()
	{
		scrollSpeed = FlxDestroyUtil.put(scrollSpeed);
		super.destroy();
	}
}
