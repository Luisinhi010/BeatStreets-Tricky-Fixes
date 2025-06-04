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

	public function new(graphicPath, x:Float = 0, y:Float = 0, ?scrollX:Float = 1.0, ?scrollY:Float = 1.0, ?loopable:Bool = false, ?autoScroll:Bool = false,
			?scrollSpeedX:Float = 0, ?scrollSpeedY:Float = 0)
	{
		super(x, y);

		loadGraphic(graphicPath);

		this.loopable = loopable;
		this.autoScroll = autoScroll;
		this.scrollSpeed = FlxPoint.get(Math.isNaN(scrollSpeedX) ? 0 : scrollSpeedX, Math.isNaN(scrollSpeedY) ? 0 : scrollSpeedY);
		antialiasing = !FlxG.save.data.lowend;
		scrollFactor.set(Math.isNaN(scrollX) ? 1.0 : scrollX, Math.isNaN(scrollY) ? 1.0 : scrollY);
		moves = active = autoScroll;
	}

	override function update(elapsed:Float)
	{
		if (autoScroll && scrollSpeed != null)
		{
			x += scrollSpeed.x * elapsed;
			y += scrollSpeed.y * elapsed;

			if (loopable && width > 0 && height > 0)
			{
				if (x > FlxG.width)
					x = -width;
				else if (x < -width)
					x = FlxG.width;
				if (y > FlxG.height)
					y = -height;
				else if (y < -height)
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
