package scripting;

import sys.FileSystem;
import haxe.Json;
import flixel.FlxCamera.FlxCameraFollowStyle;
import hscript.Interp;
import hscript.Parser;
import sys.io.File;
import haxe.Log;
import haxe.Timer;
import haxe.ds.StringMap;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

using StringTools;

class ScriptManager
{
	private static final ERROR_SCRIPT = "Script error in {0}: {1}";
	private static final ERROR_NOT_FUNCTION = "Warning: {0} is not a function";

	public var script:Interp;
	public var currentScript:String = "unknown";
	public var events:EventManager;
	private var plugins:Array<Plugin> = [];

	private var parser:Parser;
	private var program:Dynamic;
	private var scriptPath:String;

	public function new()
	{
		script = new Interp();
		parser = new Parser();
		parser.allowTypes = parser.allowMetadata = parser.allowJSON = true;
		registerDefaultFunctions();
		registerHaxeClasses();
		addGameEventHandlers();
		events = new EventManager();
		registerEventFunctions();
	}

	public function loadScript(code:String, ?path:String)
	{
		currentScript = path != null ? path : "unknown";
		try
		{
			scriptPath = path;
			program = parser.parseString(code, path);
			return executeProgram();
		}
		catch (e)
		{
			logError(ERROR_SCRIPT, [path, e.message]);
			return false;
		}
	}

	public function loadScriptFile(path:String):Bool {
        if (!FileSystem.exists(path))
            return false;
            
        return loadScript(File.getContent(path), path);
    }

	private function executeProgram():Bool
	{
		try
		{
			script.execute(program);
			return true;
		}
		catch (e)
		{
			logError(ERROR_SCRIPT, [scriptPath, e.message]);
			return false;
		}
	}

	public function setVariable(name:String, value:Dynamic)
	{
		try
		{
			script.variables.set(name, value);
			return true;
		}
		catch (e)
		{
			trace('Error setting ${name}: ${e.message}');
			return false;
		}
	}

	public function callFunction(name:String, ?args:Array<Dynamic>)
	{
		try
		{
			if (script.variables.exists(name))
			{
				var fn = script.variables.get(name);
				if (Reflect.isFunction(fn))
				{
					return Reflect.callMethod(null, fn, args);
				}
				else
				{
					trace('Warning: ${name} is not a function');
				}
			}
		}
		catch (e)
		{
			trace('Error calling ${name}: ${e.message}');
		}
		return null;
	}

	public function set(name:String, value:Dynamic):Dynamic
	{
		try
		{
			if (name.contains("."))
			{
				var split = name.split(".");
				var obj = script.variables.get(split[0]);
				var field = split[1];
				if (obj != null)
				{
					Reflect.setProperty(obj, field, value);
					return value;
				}
			}
			script.variables.set(name, value);
			return value;
		}
		catch (e)
		{
			trace('Error setting ${name}: ${e.message}');
			return null;
		}
	}

	// Função melhorada para obter variáveis
	public function get(name:String):Dynamic
	{
		try
		{
			if (name.contains("."))
			{
				var split = name.split(".");
				var obj = script.variables.get(split[0]);
				var field = split[1];
				if (obj != null)
				{
					return Reflect.getProperty(obj, field);
				}
			}
			return script.variables.get(name);
		}
		catch (e)
		{
			trace('Error getting ${name}: ${e.message}');
			return null;
		}
	}

	public function setVariables(variables:Dynamic)
	{
		try
		{
			for (field in Reflect.fields(variables))
			{
				var value = Reflect.field(variables, field);
				setNestedVariable(field, value);
			}
			return true;
		}
		catch (e)
		{
			trace('Error setting multiple variables: ${e.message}');
			return false;
		}
	}

	private function setNestedVariable(path:String, value:Dynamic)
	{
		var parts = path.split(".");
		if (parts.length == 1)
		{
			script.variables.set(path, value);
			return;
		}

		var current = script.variables.get(parts[0]);
		for (i in 1...parts.length - 1)
		{
			if (current == null)
				return;
			current = Reflect.getProperty(current, parts[i]);
		}

		if (current != null)
		{
			Reflect.setProperty(current, parts[parts.length - 1], value);
		}
	}

	public function registerDefaultFunctions()
	{
		// Função trace melhorada
		script.variables.set("trace", Reflect.makeVarArgs(function(args:Array<Dynamic>)
		{
			var pos = script.posInfos();
			var scriptName = scriptPath != null ? scriptPath.split("/").pop() : "unknown";
			Sys.println('${scriptName}:${pos.lineNumber}: ${args.join(" ")}');
		}));

		// String helpers
		script.variables.set("split", function(str:String, delimiter:String)
		{
			return str.split(delimiter);
		});

		script.variables.set("replace", function(str:String, search:String, replace:String)
		{
			return StringTools.replace(str, search, replace);
		});

		script.variables.set("trim", function(str:String)
		{
			return StringTools.trim(str);
		});

		script.variables.set("startsWith", function(str:String, prefix:String)
		{
			return StringTools.startsWith(str, prefix);
		});

		script.variables.set("endsWith", function(str:String, suffix:String)
		{
			return StringTools.endsWith(str, suffix);
		});

		// Array helpers
		script.variables.set("arrayContains", function(arr:Array<Dynamic>, item:Dynamic)
		{
			return arr.contains(item);
		});

		// Math helpers
		script.variables.set("lerp", function(start:Float, end:Float, ratio:Float)
		{
			return start + (end - start) * ratio;
		});

		script.variables.set("clamp", function(value:Float, min:Float, max:Float)
		{
			return Math.max(min, Math.min(max, value));
		});

		script.variables.set("degToRad", function(degrees:Float)
		{
			return degrees * Math.PI / 180;
		});

		script.variables.set("radToDeg", function(radians:Float)
		{
			return radians * 180 / Math.PI;
		});

		// Funções existentes
		script.variables.set("enumToString", function(enumValue:Dynamic)
		{
			return Type.enumConstructor(enumValue);
		});

		// Função para converter strings para enums
		script.variables.set("stringToEnum", function(enumType:Dynamic, enumString:String)
		{
			return Type.createEnum(enumType, enumString);
		});

		script.variables.set("setTimer", function(delay:Int, callback:Dynamic)
		{
			return Timer.delay(callback, delay);
		});

		script.variables.set("getCurrentDateTime", function()
		{
			return Date.now().toString();
		});

		script.variables.set("randomInt", function(min:Int, max:Int)
		{
			return Std.int(Math.random() * (max - min + 1)) + min;
		});

		script.variables.set("random", function(min:Float, max:Float)
		{
			return min + Math.random() * (max - min);
		});

		script.variables.set("setTimeout", function(callback:Dynamic, ms:Int)
		{
			new flixel.util.FlxTimer().start(ms / 1000, function(_)
			{
				if (Reflect.isFunction(callback))
					callback();
			});
		});

		script.variables.set("makeSprite", function(x:Float, y:Float, ?graphic:String)
		{
			var sprite = new FlxSprite(x, y);
			if (graphic != null)
				sprite.loadGraphic(Paths.image(graphic));
			return sprite;
		});

		script.variables.set("makeAnimatedSprite", function(x:Float, y:Float, graphic:String, width:Int, height:Int)
		{
			var sprite = new FlxSprite(x, y);
			sprite.frames = Paths.getSparrowAtlas(graphic);
			return sprite;
		});

		script.variables.set("addAnimation", function(sprite:FlxSprite, name:String, frames:Array<Int>, fps:Int = 24, loop:Bool = true)
		{
			sprite.animation.add(name, frames, fps, loop);
		});

		script.variables.set("playAnim", function(sprite:FlxSprite, name:String, forced:Bool = false)
		{
			sprite.animation.play(name, forced);
		});

		script.variables.set("loadSound", function(path:String)
		{
			return Paths.sound(path);
		});

		script.variables.set("playSound", function(sound:String, ?volume:Float = 1)
		{
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		script.variables.set("angleBetween", function(x1:Float, y1:Float, x2:Float, y2:Float)
		{
			return Math.atan2(y2 - y1, x2 - x1) * (180 / Math.PI);
		});

		script.variables.set("distanceBetween", function(x1:Float, y1:Float, x2:Float, y2:Float)
		{
			return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
		});

		script.variables.set("tween", function(object:Dynamic, values:Dynamic, duration:Float, ?ease:String)
		{
			FlxTween.tween(object, values, duration, {ease: getEaseByString(ease)});
		});

		script.variables.set("switchState", function(state:Class<FlxState>)
		{
			FlxG.switchState(Type.createInstance(state, []));
		});

		script.variables.set("resetState", function()
		{
			FlxG.resetState();
		});

		script.variables.set("setCameraFollow", function(target:FlxObject, ?style:String = "lockon")
		{
			var followStyle = switch (style.toLowerCase())
			{
				case "topdown": FlxCameraFollowStyle.TOPDOWN;
				case "platformer": FlxCameraFollowStyle.PLATFORMER;
				case "screen_by_screen": FlxCameraFollowStyle.SCREEN_BY_SCREEN;
				case "no_dead_zone": FlxCameraFollowStyle.NO_DEAD_ZONE;
				default: FlxCameraFollowStyle.LOCKON;
			}
			FlxG.camera.follow(target, followStyle);
		});

		script.variables.set("playCharacterAnim", function(char:Character, anim:String, forced:Bool = false)
		{
			char.playAnim(anim, forced);
		});

		script.variables.set("setScrollFactor", function(obj:FlxObject, x:Float, y:Float)
		{
			obj.scrollFactor.set(x, y);
		});
	
		script.variables.set("roundDecimal", function(value:Float, precision:Int) {
			var mult = Math.pow(10, precision);
			return Math.round(value * mult) / mult;
		});
	
		script.variables.set("rgbToHex", function(r:Int, g:Int, b:Int) {
			return '#' + StringTools.hex(r, 2) + StringTools.hex(g, 2) + StringTools.hex(b, 2);
		});

		script.variables.set("openSubState", function(scriptPath:String)
		{
			var currentState = FlxG.state;
			if (currentState != null)
			{
				var subState = new ScriptSubState(scriptPath);
				currentState.openSubState(subState);
			}
		});

		script.variables.set("closeSubState", function()
		{
			var currentState = FlxG.state;
			if (currentState != null)
			{
				currentState.closeSubState();
			}
		});

		script.variables.set("switchToScriptState", function(scriptPath:String)
		{
			FlxG.switchState(new ScriptState(scriptPath));
		});

		// Funções de persistência
		script.variables.set("persistentUpdate", function(value:Bool)
		{
			if (FlxG.state != null)
				FlxG.state.persistentUpdate = value;
		});

		script.variables.set("persistentDraw", function(value:Bool)
		{
			if (FlxG.state != null)
				FlxG.state.persistentDraw = value;
		});
	}

	public function registerHaxeClasses()
	{
		script.variables.set("Paths", Paths);
		script.variables.set("File", File);
		script.variables.set("Log", Log);
		script.variables.set("Timer", Timer);
		script.variables.set("StringMap", StringMap);
		script.variables.set("FlxG", FlxG);
		script.variables.set("FlxSprite", FlxSprite);
		script.variables.set("FlxObject", FlxObject);
		script.variables.set("FlxState", FlxState);
		script.variables.set("FlxGroup", FlxGroup);
		script.variables.set("FlxText", FlxText);
		script.variables.set("Type", Type);
		script.variables.set("FlxColorUtil", FlxColorUtil);
		script.variables.set("PlayState", PlayState);
		script.variables.set("game", PlayState.staticVar);

		script.variables.set("FlxTween", flixel.tweens.FlxTween);
		script.variables.set("FlxEase", flixel.tweens.FlxEase);
		script.variables.set("FlxTimer", flixel.util.FlxTimer);
		script.variables.set("FlxMath", flixel.math.FlxMath);
		script.variables.set("FlxSound", flixel.sound.FlxSound);
		script.variables.set("FlxCamera", flixel.FlxCamera);
		script.variables.set("CoolUtil", CoolUtil);
		script.variables.set("Conductor", Conductor);
		script.variables.set("Character", Character);
		script.variables.set("Note", Note);

		script.variables.set("ShaderFilter", openfl.filters.ShaderFilter);
		script.variables.set("BitmapData", openfl.display.BitmapData);
		script.variables.set("Std", Std);
		script.variables.set("Math", Math);
		script.variables.set("StringTools", StringTools);
		script.variables.set("Xml", Xml);
		script.variables.set("Json", Json);
		script.variables.set("Assets", openfl.utils.Assets);

		script.variables.set("HealthIcon", HealthIcon);

		// Adicione as classes de script
		script.variables.set("ScriptState", ScriptState);
		script.variables.set("ScriptSubState", ScriptSubState);
	}

	private function getEaseByString(ease:String):Dynamic
	{
		return switch (ease.toLowerCase())
		{
			case "linear": FlxEase.linear;
			case "quad": FlxEase.quadIn;
			case "cubic": FlxEase.cubeIn;
			case "quart": FlxEase.quartIn;
			case "quint": FlxEase.quintIn;
			case "sine": FlxEase.sineIn;
			case "bounce": FlxEase.bounceIn;
			case "elastic": FlxEase.elasticIn;
			case "back": FlxEase.backIn;
			case "cirq": FlxEase.circIn;
			case "expo": FlxEase.expoIn;
			default: FlxEase.linear;
		}
	}

	public function resetScript()
	{
		// Reinicializar o interpretador de script
		script = new Interp();
		registerDefaultFunctions();
		registerHaxeClasses();
		addGameEventHandlers();
	}

	public function destroy()
	{
		try
		{
			if (script != null)
			{
				script.variables.clear();
				script = null;
			}
			program = null;
			parser = null;
			events.clear();
			for (plugin in plugins)
				plugin.destroy();
			plugins = [];
		}
		catch (e)
		{
			trace('Error destroying script: ${e.message}');
		}
	}

	private function logError(template:String, params:Array<String>)
	{
		var message = template;
		for (i in 0...params.length)
			message = StringTools.replace(message, '{$i}', params[i]);
	}

	// Add new event handlers
	public function onGameEvent(eventName:String, ?args:Array<Dynamic>) {
		ScriptUtils.safeCallFunction(this, 'on${eventName}', args);
	}

	public function addGameEventHandlers() {
		// Add common game events
		set("onPause", function() {});
		set("onResume", function() {});
		set("onGameOver", function() {});
		set("onNoteHit", function(note:Note) {});
		set("onNoteMiss", function(note:Note) {});
		set("onSectionHit", function(section:Int) {});
		set("onCharacterSwap", function(oldChar:String, newChar:String) {});
		set("onStageChange", function(newStage:String) {});
		set("onModifierAdd", function(modName:String) {});
		set("onModifierRemove", function(modName:String) {});
		set("onCustomEvent", function(eventName:String, params:Dynamic) {});
	}

	private function registerEventFunctions() {
		script.variables.set("on", function(event:String, callback:Dynamic) {
			events.on(event, callback);
		});

		script.variables.set("once", function(event:String, callback:Dynamic) {
			events.once(event, callback);
		});

		script.variables.set("emit", function(event:String, ?args:Array<Dynamic>) {
			events.emit(event, args);
		});
	}

	public function addPlugin(plugin:Plugin) {
		plugin.init(this);
		plugins.push(plugin);
	}

	public function updatePlugins(elapsed:Float) {
		for (plugin in plugins)
			plugin.update(elapsed);
	}

	// Add debug mode
	public static var DEBUG:Bool = false;

	public function debug(msg:String) {
		if (DEBUG)
			ScriptUtils.logScriptInfo(currentScript, msg);
	}
}

class FlxColorUtil
{
	public inline function fromRGB(r:Int, g:Int, b:Int):Int
		return FlxColor.fromRGB(r, g, b);

	public inline function fromString(hex:String):Int
		return FlxColor.fromString(hex);

	public inline function toHexString(color:Int):String
		return new FlxColor(color).toHexString();
}
