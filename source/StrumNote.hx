package;

import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
 * Represents a receptor/strum line arrow that notes align to
 * Supports:
 * - Different graphics for player and opponent
 * - Press/confirm animations
 */
class StrumNote extends CustomSprite
{
	/**
	 * Which player this belongs to (0=opponent, 1=player)
	 */
	public var player:Int;

	/**
	 * Creates a new strum line arrow
	 * @param x X position
	 * @param y Y position  
	 * @param player Which player this belongs to (0=opponent, 1=player)
	 * @param ID Which direction/column (0-3)
	 */
	public function new(x:Float, y:Float, player:Int, ID:Int)
	{
		super(x, y);
		ConfigManager.init();

		this.player = player;
		this.ID = ID;

		var atlasPath:String = (player == 1 || FlxG.save.data.lowend) ? ConfigManager.getValue(ConfigManager.noteConfig, "paths.defaut.player",
			"customnotes/Custom_static_arrows_Bf") : ConfigManager.getValue(ConfigManager.noteConfig, "paths.defaut.opponent",
				"customnotes/Custom_static_arrows");

		frames = Paths.getSparrowAtlas(atlasPath, 'shared');

		var animationPrefixes:Array<String> = ['purple', 'blue', 'green', 'red'];
		var directions:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

		antialiasing = !FlxG.save.data.lowend;
		this.setGraphicSize(Std.int(this.width * ConfigManager.getValue(ConfigManager.noteConfig, "dimensions.scale", 0.7)));

		this.x += Note.swagWidth * ID;
		var direction = directions[ID];
		animation.addByPrefix('static', 'arrow$direction');
		animation.addByPrefix('pressed', '${direction.toLowerCase()} press', 24, false);
		animation.addByPrefix('confirm', '${direction.toLowerCase()} confirm', 24, false);

		updateHitbox();
		scrollFactor.set();

		animation.play('static');
	}
}
