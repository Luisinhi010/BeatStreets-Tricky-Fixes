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
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class ScriptManager
{
	private static final ERROR_SCRIPT = "Script error in {0}: {1}";
	private static final ERROR_NOT_FUNCTION = "Warning: {0} is not a function";

	public var script:Interp;
	public var currentScript:String = "unknown";
	public var events:EventManager;

	private var parser:Parser;
	private var program:Dynamic;
	private var scriptPath:String;
	
	public static var DEBUG:Bool = false; // Flag para controle de debug

	public function new()
	{
		script = new Interp();
		parser = new Parser();
		parser.allowTypes = parser.allowMetadata = parser.allowJSON = true;
		registerDefaultFunctions();
		registerHaxeClasses();
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
			trace('Script analisado com sucesso: $path');// Translated
			return executeProgram();
		}
		catch (e)
		{
			logError(ERROR_SCRIPT, [path, e.message]);
			return false;
		}
	}

	public function loadScriptFile(path:String):Bool
	{
		var normalizedPath = path.replace("\\", "/");
		var isAssetPath = !normalizedPath.startsWith('/') && !normalizedPath.contains(':');
		
		if (isAssetPath)
		{
			// É um caminho relativo à pasta de assetser
			if (!Paths.exists(normalizedPath))
			{
				trace('Script não encontrado no caminho de assets: $normalizedPath');
				return false;
			}
			
			var content = Paths.getText(normalizedPath);
			return loadScript(content, normalizedPath);
		}
		else
		{
			// É um caminho absolutoath
			if (!sys.FileSystem.exists(normalizedPath))
			{
				trace('Script não encontrado no caminho absoluto: $normalizedPath');
				return false;
			}
			
			var content = sys.io.File.getContent(normalizedPath);
			return loadScript(content, normalizedPath);
		}
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
			if (DEBUG) trace('Tentando chamar função: $name' + (args != null ? ' com args: $args' : ''));
			
			if (script.variables.exists(name))
			{
				var fn = script.variables.get(name);
				if (Reflect.isFunction(fn))
				{
					if (DEBUG) trace('Função $name encontrada, chamando');
					return Reflect.callMethod(null, fn, args != null ? args : []);
				}
				else
				{
					trace('Aviso: $name existe mas não é uma função');
				}
			}
			else
			{
				if (DEBUG)
				{
					trace('Função $name não existe no script');
				
					// Lista as funções disponíveis para debug
					var availableFunctions = [];
					for (key in script.variables.keys())
					{
						if (Reflect.isFunction(script.variables.get(key)))
							availableFunctions.push(key);
					}
				
					if (availableFunctions.length > 0)
						trace('Funções disponíveis: ' + availableFunctions.join(", "));
				}
			}
		}
		catch (e)
		{
			trace('Erro ao chamar ${name}: ${e.message}');
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
		script.variables.set("trace", Reflect.makeVarArgs(function(args:Array<Dynamic>)
		{
			var pos = script.posInfos();
			var scriptName = scriptPath != null ? scriptPath.split("/").pop() : "unknown";
			var scriptLine = pos != null ? Std.string(pos.lineNumber) : "?";
			var scriptPos = pos != null && pos.fileName != null ? pos.fileName : scriptPath;
			Sys.println('[${scriptName}:${scriptLine}] ${args.join(" ")}');
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

		// Existing functions
		script.variables.set("enumToString", function(enumValue:Dynamic)
		{
			return Type.enumConstructor(enumValue);
		});

		// Function to convert strings to enums
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

		script.variables.set("roundDecimal", function(value:Float, precision:Int)
		{
			var mult = Math.pow(10, precision);
			return Math.round(value * mult) / mult;
		});

		script.variables.set("rgbToHex", function(r:Int, g:Int, b:Int)
		{
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

		// Persistence functions
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
		
		// Advanced visual functions mentioned in the documentation
		script.variables.set("flashSprite", function(sprite:FlxSprite, color:Int, duration:Float)
		{
			sprite.color = color;
			FlxTween.tween(sprite, {color: 0xFFFFFF}, duration);
		});
		
		script.variables.set("shakeCamera", function(intensity:Float = 0.05, duration:Float = 0.5, ?camera:FlxCamera)
		{
			var cam = camera != null ? camera : FlxG.camera;
			cam.shake(intensity, duration);
		});
		
		script.variables.set("createEffect", function(target:FlxSprite, type:String, ?duration:Float = 0.5)
		{
			var effect:FlxSprite = null;
			if (FlxG.state == null)
			{
				trace("Warning: FlxG.state is null, could not create the effect");
				return null;
			}
			
			switch (type.toLowerCase())
			{
				case "fade":
					effect = new FlxSprite(target.x, target.y).loadGraphic(target.graphic);
					effect.alpha = 0.8;
					FlxG.state.add(effect);
					FlxTween.tween(effect, {alpha: 0}, duration, 
						{onComplete: function(twn) { effect.destroy(); }});
				
				case "glow":
					effect = new FlxSprite(target.x - 10, target.y - 10).makeGraphic(
						Std.int(target.width + 20), 
						Std.int(target.height + 20), 
						0x88FFFFFF);
					FlxG.state.add(effect);
					FlxTween.tween(effect, {alpha: 0}, duration, 
						{onComplete: function(twn) { effect.destroy(); }});
					
				case "pixel":
					// Simplified pixelation effect
					effect = new FlxSprite(target.x, target.y).loadGraphic(target.graphic);
					effect.antialiasing = false;
					effect.scale.set(0.8, 0.8);
					FlxG.state.add(effect);
					FlxTween.tween(effect, {alpha: 0}, duration, 
						{onComplete: function(twn) { effect.destroy(); }});
			}
			
			return effect;
		});
		
		script.variables.set("createTrail", function(target:FlxSprite, length:Int = 10, delay:Float = 0.05, 
			alpha:Float = 0.3, diff:Float = 0.05)
		{
			var trailGroup = new FlxTypedGroup<FlxSprite>();
			FlxG.state.add(trailGroup);
			
			// Create the initial ghost trail
			for (i in 0...length)
			{
				var trail = new FlxSprite(target.x, target.y).loadGraphic(target.graphic);
				trail.alpha = alpha - (diff * i);
				trail.visible = false;
				trailGroup.add(trail);
			}
			
			// Timer to update the trail
			var timer = new FlxTimer();
			timer.start(delay, function(tmr:FlxTimer) 
			{
				if (trailGroup != null && trailGroup.members != null)
				{

					var i = length - 1;
					while (i > 0)
					{
						var current = trailGroup.members[i];
						var prev = trailGroup.members[i-1];
						if (current != null && prev != null)
						{
							current.x = prev.x;
							current.y = prev.y;
							current.angle = prev.angle;
							current.scale.set(prev.scale.x, prev.scale.y);
							current.visible = true;
						}
						i--;
					}
					
					// Update the first sprite to the current position
					var first = trailGroup.members[0];
					if (first != null)
					{
						first.x = target.x;
						first.y = target.y;
						first.angle = target.angle;
						first.scale.set(target.scale.x, target.scale.y);
						first.visible = true;
					}
				}
				
				tmr.reset(delay);
			});
			
			return {
				trailGroup: trailGroup,
				destroy: function() {
					timer.cancel();
					trailGroup.kill();
					trailGroup.destroy();
				}
			};
		});
		
		// Performance profiling support
		script.variables.set("startPerfTimer", function(name:String) {
			if (!DEBUG) return;
			
			var timerMap:Map<String, Float> = script.variables.exists("__perfTimers") 
				? script.variables.get("__perfTimers") 
				: new Map<String, Float>();
				
			timerMap.set(name, Date.now().getTime());
			script.variables.set("__perfTimers", timerMap);
		});
		
		script.variables.set("endPerfTimer", function(name:String) {
			if (!DEBUG) return;
			
			var timerMap:Map<String, Float> = script.variables.exists("__perfTimers") 
				? script.variables.get("__perfTimers") : null;
				
			if (timerMap != null && timerMap.exists(name)) {
				var startTime = timerMap.get(name);
				var endTime = Date.now().getTime();
				var elapsed = endTime - startTime;
				trace('Perf [${name}]: ${elapsed}ms');
				timerMap.remove(name);
			}
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
		script.variables.set("Game", PlayState.staticVar);

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
		script.variables.set("CustomCamera", CustomCamera);
		script.variables.set("CustomSprite", CustomSprite);

		script.variables.set("ShaderFilter", openfl.filters.ShaderFilter);
		script.variables.set("BitmapData", openfl.display.BitmapData);
		script.variables.set("Std", Std);
		script.variables.set("Math", Math);
		script.variables.set("StringTools", StringTools);
		script.variables.set("Xml", Xml);
		script.variables.set("Json", Json);
		script.variables.set("Assets", openfl.utils.Assets);

		script.variables.set("HealthIcon", HealthIcon);

		// Add script classes
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
		script = new Interp();
		registerDefaultFunctions();
		registerHaxeClasses();
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
		
		if (DEBUG)
			Sys.println('[ERROR] $message');
		else
			Sys.println(message);
	}

	private function registerEventFunctions()
	{
		script.variables.set("on", function(event:String, callback:Dynamic)
		{
			events.on(event, callback);
		});

		script.variables.set("once", function(event:String, callback:Dynamic)
		{
			events.once(event, callback);
		});

		script.variables.set("emit", function(event:String, ?args:Array<Dynamic>)
		{
			events.emit(event, args);
		});
	}
	
	// Method to reload the current script (hot-reload)
	public function reloadCurrentScript():Bool 
	{
		if (scriptPath != null && FileSystem.exists(scriptPath))
		{
			try 
			{
				var code = File.getContent(scriptPath);
				// Save important variables
				var savedVars = new Map<String, Dynamic>();
				for (key in ["state", "subState", "game"]) {
					if (script.variables.exists(key))
						savedVars.set(key, script.variables.get(key));
				}
				
				// Reload the script
				script = new Interp();
				registerDefaultFunctions();
				registerHaxeClasses();
				
				// Restore important variables
				for (key in savedVars.keys())
					script.variables.set(key, savedVars.get(key));
				
				// Parse and execute
				program = parser.parseString(code, scriptPath);
				var success = executeProgram();
				
				if (DEBUG)
					trace(success ? "Script reloaded successfully" : "Error reloading script");
				
				return success;
			}
			catch (e) {
				logError("Error reloading script {0}: {1}", [scriptPath, e.message]);
				return false;
			}
		}
		return false;
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
