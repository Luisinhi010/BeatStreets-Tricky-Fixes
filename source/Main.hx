package;

import flixel.tweens.FlxTween;
import openfl.text.TextFormat;
import openfl.text.TextField;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		#if !debug
		initialState = TitleState;
		#end

		game = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);
		addChild(game);

		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		toggleFPS(FlxG.save.data.fps);
		#end

		debug = new TextField();
		debug.selectable = false;
		debug.mouseEnabled = false;
		debug.defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 22, 0xFFFFFF);
		debug.autoSize = LEFT;
		debug.x = 10;
		debug.y = fpsCounter.y + 18;
		debug.alpha = 0;
		addChild(debug);

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		// shader coords fix
		/*
			FlxG.signals.gameResized.add(function(w, h)
				{
					if (FlxG.cameras != null)
					{
						for (cam in FlxG.cameras.list)
						{
							@:privateAccess
							if (cam != null && cam._filters != null)
								resetSpriteCache(cam.flashSprite);
						}
					}

					if (FlxG.game != null)
						resetSpriteCache(FlxG.game);
					showDebugText('shaders fix');
			});
		 */
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	var game:FlxGame;

	public static var fpsCounter:FPS;
	public static var debug:TextField;
	public static var debugTween:FlxTween;

	public static function showDebugText(text:String):Void
	{
		if (debugTween != null)
			debugTween.cancel();
		debug.text = text;
		debug.alpha = 1;
		debugTween = FlxTween.tween(debug, {alpha: 0}, 0.5, {
			// startDelay: 1,
			onComplete: function(twn:FlxTween)
			{
				debugTween = null;
			}
		});
	}

	public function toggleFPS(fpsEnabled:Bool):Void
		fpsCounter.visible = fpsEnabled;

	public function setFPSCap(cap:Float)
		openfl.Lib.current.stage.frameRate = cap;

	public function getFPSCap():Float
		return openfl.Lib.current.stage.frameRate;

	public function getFPS():Float
		return fpsCounter.currentFPS;

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var errMsgPrint:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "MadnessMakeover_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
					errMsgPrint += file + ":" + line + "\n"; // if you Ctrl+Mouse Click its go to the line. -Luis
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += '\nUncaught Error: ${e.error}' // + "\n Version: 1.0"
			+
			"\nPlease report this error to the GitHub page: https://github.com/Luisinhi010/BeatStreets-Tricky-Fixes\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsgPrint + '\n' + e.error);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}
}
