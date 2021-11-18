package;

import lime.app.Application;
#if windows
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;

using StringTools;

class Shit extends MusicBeatState
{
	var Tricky:FlxSprite;

	var text:FlxText;

	var images = [];
	var music = [];
	var charts = [];

	override function create()
		FlxG.mouse.visible = true;

	// text = new FlxText(12, healthBarBG.y - 84, 0, "Vs tricky by Banbuds", 12);
	// text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300, 0, "Warning, this is a fan fix for The Full BeatStreets Tricky Remixes Mod");
	// text.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
	// text.screenCenter();
	// text.size = 34;
	// text.alignment = FlxTextAlign.CENTER;
	// text.alpha = 0;
	// kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('KadeEngineLogo'));
	// kadeLogo.x -= kadeLogo.width / 2;
	// kadeLogo.y -= kadeLogo.height / 2 + 100;
	// text.y -= kadeLogo.height / 2 - 125;
	// text.x -= 170;
	// kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.6));
	// if(FlxG.save.data.antialiasing != null)
	if (FlxG.mouse.justPressed || FlxG.keys.justPressed.ENTER)
	{
		FlxG.camera.flash(FlxColor.BLUE, 1);
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		transitioning = true;
		// FlxG.sound.music.stop();
		FlxG.sound.music.fadeOut(1, 0);
		new FlxTimer().start(1.4, function(tmr:FlxTimer)
		{
			FlxG.switchState(new MainMenuState());
		});
	}
}
