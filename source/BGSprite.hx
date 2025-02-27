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
this.loopable = loopable != null ? loopable : false;
this.autoScroll = autoScroll != null ? autoScroll : false;
		this.scrollSpeed = FlxPoint.get(scrollSpeedX, scrollSpeedY);
		antialiasing = !FlxG.save.data.lowend;
		scrollFactor.set(scrollX, scrollY);
		moves = active = autoScroll;
	}

override function update(elapsed:Float)
{
	if (autoScroll)
		updatePosition(elapsed);
	super.update(elapsed);
}

private function updatePosition(elapsed:Float)
{
	x += scrollSpeed.x * elapsed;
	y += scrollSpeed.y * elapsed;

	if (loopable)
		wrapPosition();
}

private function wrapPosition()
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

	override function destroy()
	{
		scrollSpeed = FlxDestroyUtil.put(scrollSpeed);
		super.destroy();
	}
}
