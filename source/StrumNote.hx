package;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class StrumNote extends FlxSprite
{
	public var player:Int;

	public function new(x:Float, y:Float, player:Int, ID:Int)
	{
		super(x, y);
		this.player = player;
		this.ID = ID;

		var atlasPath:String;

		if (player == 1 || FlxG.save.data.lowend)
			atlasPath = 'customnotes/Custom_static_arrows_Bf';
		else
			atlasPath = 'customnotes/Custom_static_arrows';

		this.frames = Paths.getSparrowAtlas(atlasPath, 'shared');

		this.animation.addByPrefix('green', 'arrowUP');
		this.animation.addByPrefix('blue', 'arrowDOWN');
		this.animation.addByPrefix('purple', 'arrowLEFT');
		this.animation.addByPrefix('red', 'arrowRIGHT');

		this.antialiasing = !FlxG.save.data.lowend;
		this.setGraphicSize(Std.int(this.width * 0.7));

		switch (Math.abs(ID))
		{
			case 0:
				this.x += Note.swagWidth * 0;
				this.animation.addByPrefix('static', 'arrowLEFT');
				this.animation.addByPrefix('pressed', 'left press', 24, false);
				this.animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				this.x += Note.swagWidth * 1;
				this.animation.addByPrefix('static', 'arrowDOWN');
				this.animation.addByPrefix('pressed', 'down press', 24, false);
				this.animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				this.x += Note.swagWidth * 2;
				this.animation.addByPrefix('static', 'arrowUP');
				this.animation.addByPrefix('pressed', 'up press', 24, false);
				this.animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				this.x += Note.swagWidth * 3;
				this.animation.addByPrefix('static', 'arrowRIGHT');
				this.animation.addByPrefix('pressed', 'right press', 24, false);
				this.animation.addByPrefix('confirm', 'right confirm', 24, false);
		}

		this.updateHitbox();
		this.scrollFactor.set();

		this.animation.play('static');
	}
}
