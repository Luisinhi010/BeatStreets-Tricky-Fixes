package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	private var isPlayer:Bool = false;
	private var char:String = '';

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			switch (char)
			{
				case 'TrickyMask' | 'Tricky':
					loadGraphic(Paths.image('IconGridTricky', 'clown'), true, 150, 150);
					animation.add('Tricky', [2, 3], 0, false, isPlayer);
					animation.add('TrickyMask', [0, 1], 0, false, isPlayer);

				case 'Tricky-old' | 'TrickyMask-old':
					loadGraphic(Paths.image('IconGridTricky-old', 'clown'), true, 150, 150);
					animation.add('Tricky-old', [2, 3], 0, false, isPlayer);
					animation.add('TrickyMask-old', [0, 1], 0, false, isPlayer);

				case 'Tricky-upside' | 'TrickyMask-upside':
					loadGraphic(Paths.image('IconGridTricky-upside', 'clown'), true, 150, 150);
					animation.add('Tricky-upside', [2, 3], 0, false, isPlayer);
					animation.add('TrickyMask-upside', [0, 1], 0, false, isPlayer);

				case 'TrickyH':
					loadGraphic(Paths.image('hellclwn/hellclownIcon', 'clown'), true, 150, 150);
					animation.add('TrickyH', [0, 1], 0, false, isPlayer);
					offset.y = 25;

				case 'exTricky':
					loadGraphic(Paths.image('fourth/exTrickyIcons', 'clown'), true, 150, 150);
					animation.add('exTricky', [0, 1], 0, false, isPlayer);

				case 'bf-upside':
					loadGraphic(Paths.image('IconGridBf-upside'), true, 150, 150);
					animation.add('bf-upside', [0, 1], 0, false, isPlayer);

				default:
					loadGraphic(Paths.image('IconGridBf'), true, 150, 150);
					animation.add(char, [0, 1], 0, false, isPlayer);
			}
			offset.x = isPlayer ? -10 : 25;
			animation.play(char);
			this.char = char;
			antialiasing = !FlxG.save.data.lowend;
		}
	}

	override function updateHitbox()
	{
		width = Math.abs(scale.x) * frameWidth;
		height = Math.abs(scale.y) * frameHeight;
		centerOrigin();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
