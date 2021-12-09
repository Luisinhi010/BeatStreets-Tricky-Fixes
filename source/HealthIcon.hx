package;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var defaultIconScale:Float = 1;
	public var iconScale:Float = 1;
	public var iconSize:Float;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		switch (char)
		{
			case 'trickyMask' | 'tricky':
				loadGraphic(Paths.image('IconGridTricky', 'clown'), true, 150, 150);
				iconScale = 0.5;
				defaultIconScale = 0.5;

				antialiasing = true;
				animation.add('tricky', [2, 3], 0, false, isPlayer);
				animation.add('trickyMask', [0, 1], 0, false, isPlayer);
			case 'trickyH':
				loadGraphic(Paths.image('hellclwn/hellclownIcon', 'clown'), true, 150, 150);
				iconScale = 0.5;
				defaultIconScale = 0.5;

				animation.add('trickyH', [0, 1], 0, false, isPlayer);
				y -= 25;
			case 'exTricky':
				loadGraphic(Paths.image('fourth/exTrickyIcons', 'clown'), true, 150, 150);
				iconScale = 0.5;
				defaultIconScale = 0.5;

				animation.add('exTricky', [0, 1], 0, false, isPlayer);
			default:
				loadGraphic(Paths.image('iconGrid'), true, 150, 150);
				iconScale = 0.5;
				defaultIconScale = 0.5;

				antialiasing = true;
				animation.add('bf', [0, 1], 0, false, isPlayer);
				animation.add('bf-hell', [0, 1], 0, false, isPlayer);
				animation.add('gf', [16], 0, false, isPlayer);
				animation.add('gf-hell', [16], 0, false, isPlayer);
		}
		animation.play(char);
		antialiasing = true;
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateHitbox();

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
