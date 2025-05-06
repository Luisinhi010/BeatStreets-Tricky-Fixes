package;

import scripting.ScriptHandler;
import haxe.Timer;
import haxe.Json;
import openfl.events.KeyboardEvent;
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
	public static inline var gameWidth:Int = 1280;
	public static inline var gameHeight:Int = 720;
	public static inline var initialState:Class<FlxState> = TitleState;
	public static inline var framerate:Int = 120;
	public static inline var skipSplash:Bool = true;
	public static inline var startFullscreen:Bool = false;
	public static var gameVersion:String = "1.1.0A";

	public static var fpsCounter:FPS;
	public static var debug:TextField;
	public static var debugTween:FlxTween;

	public function new()
	{
		super();
		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?_:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	private function setupGame():Void
	{
		// Inicializar sistemas
		ModManager.init();
		ScriptHandler.init();

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		addChild(fpsCounter = new FPS(10, 3, 0xFFFFFF));
		toggleFPS(FlxG.save.data.fps);
		#end

		debug = new TextField();
		debug.selectable = debug.mouseEnabled = false;
		debug.defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 22, 0xFFFFFF);
		debug.autoSize = LEFT;
		debug.x = 10;
		debug.y = #if !mobile fpsCounter.y + 18 #else 10 #end;
		debug.alpha = 0;
		addChild(debug);

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		// shader coords fix
		FlxG.signals.gameResized.add(onGameResized);
	}

	private function onGameResized(_:Int, _:Int):Void
	{
		@:privateAccess
		for (cam in FlxG.cameras.list)
		{
			if (cam != null && cam.filters != null)
				resetSpriteCache(cam.flashSprite);
		}
		resetSpriteCache(FlxG.game);
		// showDebugText('shaders fix');
	}

	inline static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	public static inline function showDebugText(text:String):Void
	{
		if (debugTween != null)
			debugTween.cancel();

		debug.text = text;
		debug.alpha = 1;

		debugTween = FlxTween.tween(debug, {alpha: 0}, 0.5, {
			startDelay: 1,
			onComplete: (_:FlxTween) -> debugTween = null
		});
	}

	public static inline function toggleFPS(fpsEnabled:Bool):Void
	{
		#if !mobile
		fpsCounter.visible = fpsEnabled;
		#end
	}

	public static inline function setFPSCap(cap:Float):Void
	{
		if (cap >= 60 && cap <= 290)
			Lib.current.stage.frameRate = cap;
	}

	public static inline function getFPSCap():Float
	{
		return Lib.current.stage.frameRate;
	}

	public static inline function getFPS():Float
	{
		return #if !mobile fpsCounter.currentFPS #else 60.0 #end; // Conditional FPS
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
		errMsg += getSystemInfo() + '\n';
		errMsg += getGPUInfo(stage) + '\n';
		errMsg += getMemoryUsage() + '\n';
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
		errMsg += "\nMod Information:\n";
		errMsg += 'Active Mods: ${ModManager.activeMods.length}\n';
		for (mod in ModManager.activeMods)
		{
			errMsg += '- ${mod.name} v${mod.version} by ${mod.author}\n';
		}

		errMsg += "\nScript Information:\n";
		errMsg += 'Active Scripts: ${ScriptHandler.getActiveScriptCount()}\n';
		for (scriptId in ScriptHandler.scripts.keys())
		{
			errMsg += '- $scriptId\n';
		}

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

	public static function getGPUInfo(stage:openfl.display.Stage):String
	{
		var gl = stage.context3D;
		return 'GPU: ${gl.driverInfo}';
	}

	public static function getSystemInfo():String
	{
		return 'OS: ${Sys.systemName()}\n' + 'CPU: ${Sys.environment()["PROCESSOR_IDENTIFIER"]}\n' + 'Arch: ${Sys.environment()["PROCESSOR_ARCHITECTURE"]}';
	}

	public static function getMemoryUsage():String
	{
		var mem = System.totalMemory;
		return 'Memory: ${Math.abs(Math.round(mem / 1024 / 1024))}MB';
	}

	public static function cleanMemory():Void
	{
		System.gc();
		trace("Memory cleaned!");
	}

	public static function reloadMods():Void
	{
		showDebugText("Reloading mods...");
		ModManager.loadMods();
		ScriptHandler.clearScripts();
		showDebugText("Mods reloaded!");
	}
}
