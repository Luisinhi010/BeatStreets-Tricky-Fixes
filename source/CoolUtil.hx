package;

import flixel.FlxSprite;
import flixel.util.FlxAxes;
import lime.utils.Assets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['Hard', 'Old', 'Upside'];

	inline public static function capitalize(text:String):String
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	public static function difficultyString():String
		return difficultyArray[PlayState.storyDifficulty];

	public static function cutDownSuffix(text:String):String
	{
		var suffixes = ['-old', '-upside'];
		for (suffix in suffixes)
			if (text.toLowerCase().endsWith(suffix))
				return text.substring(0, text.length - suffix.length);

		return text;
	}

	public static function coolTextFile(path:String):Array<String>
		return getText(Assets.getText(path));

	public static function coolStringFile(path:String):Array<String>
		return getText(path);

	private static function getText(text:String):Array<String>
	{
		var daList:Array<String> = text.trim().split('\n');
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	public static function centerOnSprite(s:FlxSprite, t:FlxSprite, ?axes:FlxAxes = FlxAxes.XY):Void
	{
		if (axes == FlxAxes.XY || axes == FlxAxes.X)
			s.x = t.x + (t.width / 2) - (s.width / 2);
		if (axes == FlxAxes.XY || axes == FlxAxes.Y)
			s.y = t.y + (t.height / 2) - (s.height / 2);
	}

	public static function exactSetGraphicSize(obj:FlxSprite, width:Float, height:Float)
	{
		obj.scale.set(Math.abs(((obj.width - width) / obj.width) - 1), Math.abs(((obj.height - height) / obj.height) - 1));
		obj.updateHitbox();
	}

	public static function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	public static function lerp(a:Float, b:Float, t:Float):Float
	{
		return a + (b - a) * t;
	}

	public static function clamp(value:Float, min:Float, max:Float):Float
	{
		if (value < min)
			return min;
		if (value > max)
			return max;
		return value;
	}

	public static function randomRange(min:Float, max:Float):Float
	{
		return min + Math.random() * (max - min);
	}

	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		var range = max - min;
		return (value - min) % range + min;
	}

	public static function map(value:Float, inMin:Float, inMax:Float, outMin:Float, outMax:Float):Float
	{
		return (value - inMin) / (inMax - inMin) * (outMax - outMin) + outMin;
	}

	public static function approach(start:Float, end:Float, shift:Float):Float
	{
		if (start < end)
			return Math.min(start + shift, end);
		else
			return Math.max(start - shift, end);
	}
}
