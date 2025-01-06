package;

import openfl.display.PNGEncoderOptions;
import openfl.system.System;
import flixel.tweens.FlxTween;
import openfl.text.TextFormat;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import sys.io.File;
import sys.FileSystem;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageFileFormat;

using StringTools;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var framerate:Int = 120; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var gameVersion:String = "1.1.0A"; // The version of the game.

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();
		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	private function setupGame():Void
	{
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
			startDelay: 1,
			onComplete: function(twn:FlxTween)
			{
				debugTween = null;
			}
		});
	}

	public function toggleFPS(fpsEnabled:Bool):Void
		fpsCounter.visible = fpsEnabled;

	public function setFPSCap(cap:Float)
	{
		if (cap >= 60 && cap <= 290)
			openfl.Lib.current.stage.frameRate = cap;
	}

	public function getFPSCap():Float
	{
		return openfl.Lib.current.stage.frameRate;
	}

	public function getFPS():Float
	{
		return fpsCounter != null ? fpsCounter.currentFPS : 60.0;
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	private static var recoveryAttempts:Int = 0;
	private static var lastCrashTime:Float = 0;

	function onCrash(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopImmediatePropagation();

		var currentTime = Date.now().getTime();

		if (currentTime - lastCrashTime > 10000)
			recoveryAttempts = 0;

		lastCrashTime = currentTime;

		recoveryAttempts++;

		var errMsg:String = "========================================\n";
		errMsg += "           Crash Handler Report\n";
		errMsg += "========================================\n\n";
		var errMsgPrint:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);

		var now = Date.now();
		var dateNow:String = DateTools.format(now, "%Y-%m-%d_%H'%M'%S");

		var crashDir = "./crash/" + DateTools.format(now, "%Y-%m-%d");
		var crashCount = 0;

		if (!FileSystem.exists(crashDir))
			FileSystem.createDirectory(crashDir);
		else
			for (file in FileSystem.readDirectory(crashDir))
				if (file.endsWith(".txt"))
					crashCount++;

		path = crashDir + "/crash_" + dateNow + "_(" + (crashCount + 1) + ").txt";

		errMsg += "----------------------------------------\n";
		errMsg += "General Information:\n";
		errMsg += 'Date/Time: ${DateTools.format(now, "%d/%m/%Y %H:%M:%S")}\n';
		errMsg += 'Game Version: ${Main.gameVersion}\n';
		errMsg += 'Crash Count: ${crashCount + 1} (today)\n\n';

		errMsg += "----------------------------------------\n";
		errMsg += "System Information:\n";
		errMsg += 'Operating System: ${Sys.systemName()}\n';
		errMsg += 'Architecture: ${Sys.environment()["PROCESSOR_ARCHITECTURE"]}\n';
		errMsg += 'CPU: ${Sys.environment()["PROCESSOR_IDENTIFIER"]}\n';
		errMsg += 'Total Memory: ${Math.round(System.totalMemory / 1024 / 1024)}MB\n';
		#if windows
		errMsg += 'Windows Version: ${Sys.environment()["OS"]}\n';
		#end

		errMsg += "----------------------------------------\n";
		errMsg += "\nEngine Information:\n";
		errMsg += 'Flixel: ${flixel.FlxG.VERSION.toString()}\n';
		errMsg += 'Framerate: ${getFPS()}/${getFPSCap()}\n';

		errMsg += "----------------------------------------\n";
		errMsg += "\nGame State:\n";
		errMsg += 'Current State: ${Type.getClassName(Type.getClass(FlxG.state))}\n';
		errMsg += 'Sub-State: ${Type.getClassName(Type.getClass(FlxG.state.subState))}\n';
		errMsg += 'Active Cameras: ${FlxG.cameras.list.length}\n';
		errMsg += 'Objects on Screen: ${FlxG.state.members.length}\n';
		errMsg += 'Debug Mode: ${#if debug true #else false #end}\n';

		errMsg += "----------------------------------------\n";
		errMsg += "\nStack Trace:\n";
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += '> ${file} (line ${line}, column ${column})\n';
					errMsgPrint += file + ":" + line + "\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "----------------------------------------\n";
		errMsg += "\nError Details:\n";
		errMsg += 'Type: ${Type.getClassName(Type.getClass(e.error))}\n';
		errMsg += 'Message: ${e.error}\n';

		errMsg += "\n========================================\n";
		errMsg += "Please report this error on GitHub:\n";
		errMsg += "https://github.com/Luisinhi010/BeatStreets-Tricky-Fixes\n";
		errMsg += "----------------------------------------\n";
		errMsg += "Include this file and a description of how\n";
		errMsg += "the error occurred to help with the fix.\n";
		errMsg += "========================================";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println("\n==========================================");
		Sys.println("            CRASH REPORT");
		Sys.println("==========================================\n");

		Sys.println("Last Debug Logs:");
		Sys.println("------------------------------------------");

		Sys.println("\nStack Trace:");
		Sys.println("------------------------------------------");
		Sys.println(errMsgPrint + '\n' + e.error);
		Sys.println("\nCrash dump saved at " + Path.normalize(path));
		Sys.println("==========================================");

		if (recoveryAttempts >= 5)
		{
			Sys.println("Too many crashes in a short period. Exiting game.");
			Sys.exit(1);
		}

		var alertMsg = 'An error has occurred!\n\n';
		alertMsg += 'Type: ${Type.getClassName(Type.getClass(e.error))}\n';
		alertMsg += 'Message: ${e.error}\n\n';
		alertMsg += 'A detailed report has been saved at:\n${Path.normalize(path)}\n\n';

		var recoveryTimeLeft = 10 - Math.floor((Date.now().getTime() - lastCrashTime) / 1000);
		alertMsg += 'Time left to recover: ${recoveryTimeLeft} seconds';

		var screenshotPath = path.replace(".txt", ".png");
		saveScreenshot(screenshotPath);

		showRecoveryMessage(alertMsg);
	}

	private function saveScreenshot(path:String):Void
{
    var bitmapData = new BitmapData(stage.stageWidth, stage.stageHeight);
    var matrix = new Matrix(); 
    matrix.scale(stage.stageWidth / gameWidth, stage.stageHeight / gameHeight);

    for (camera in FlxG.cameras.list)
    {
        var cameraBitmapData = new BitmapData(camera.width, camera.height);
        cameraBitmapData.draw(camera.canvas);
        matrix.tx = camera.x;
        matrix.ty = camera.y;
        bitmapData.draw(cameraBitmapData, matrix);
    }

    bitmapData.draw(stage, matrix);

    var byteArray = new ByteArray();
    bitmapData.encode(new Rectangle(0, 0, stage.stageWidth, stage.stageHeight), new PNGEncoderOptions(), byteArray);
    File.saveBytes(path, byteArray);
}


	private function showRecoveryMessage(msg:String):Void
	{
		var recoveryText = new TextField();
		recoveryText.defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFF);
		recoveryText.text = msg;
		recoveryText.autoSize = LEFT;
		recoveryText.x = (gameWidth - recoveryText.width) / 2;
		recoveryText.y = 10;
		recoveryText.alpha = 0.8;
		recoveryText.backgroundColor = 0x88000000;
		recoveryText.background = true;

		addChild(recoveryText);

		FlxTween.tween(recoveryText, {alpha: 0}, 3, {
			startDelay: 3,
			onComplete: function(_)
			{
				removeChild(recoveryText);
			}
		});
	}
}
