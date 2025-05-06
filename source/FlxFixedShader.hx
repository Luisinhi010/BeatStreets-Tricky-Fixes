import flixel.system.FlxAssets.FlxShader;
import openfl.display3D._internal.GLRenderbuffer;
import openfl.display3D._internal.GLFramebuffer;
import openfl.display._internal.ShaderBuffer;
import openfl.display.ShaderParameter;
import haxe.Timer;

using StringTools;

/** Extended FlxShader that provides shader caching and better GLSL version handling */
class FlxFixedShader extends FlxShader
{
	/** Whether the shader is custom or uses default */
	public var custom:Bool = false;

	/** Whether to save the program in cache */
	public var save:Bool = true;

	/** Cache timeout in seconds */
	public static var CACHE_TIMEOUT:Float = 300; // 5 minutes

	/** Minimum time between cache cleanups in seconds */
	private static inline var MIN_CLEANUP_INTERVAL:Float = 60;

	/** Maximum cache size before forced cleanup */
	private static inline var MAX_CACHE_SIZE:Int = 100;

	/** Program cache by ID */
	private static var programCache:Map<String, CachedProgram> = new Map();

	/** Last cache cleanup timestamp */
	private static var lastCacheCleanup:Float = 0;

	/** Debug mode */
	public static var DEBUG:Bool = #if debug true #else false #end;

	public function new(?save:Bool)
	{
		if (save != null)
			this.save = save;
		super();
		cleanup();
	}

	/** Cleans up old programs from cache */
	private static function cleanup():Void
	{
		var now = Timer.stamp();

		// Force cleanup if cache gets too large
		var shouldForceCleanup = Lambda.count(programCache) > MAX_CACHE_SIZE;

		if (!shouldForceCleanup && now - lastCacheCleanup < MIN_CLEANUP_INTERVAL)
			return;

		if (DEBUG)
			trace('Cleaning shader cache (Forced: $shouldForceCleanup)');

		var initialSize = Lambda.count(programCache);
		var expired = [];

		for (id => program in programCache)
		{
			if (shouldForceCleanup || now - program.timestamp > CACHE_TIMEOUT)
				expired.push(id);
		}

		for (id in expired)
			programCache.remove(id);

		if (DEBUG && expired.length > 0)
			trace('Cleaned ${expired.length} shaders from cache (${initialSize} -> ${Lambda.count(programCache)})');

		lastCacheCleanup = now;
	}

	@:noCompletion private override function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;

			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();

			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
		}

		if (__context != null && program == null)
			initGLforce();
	}

	public function initGLforce():Void
	{
		if (!custom)
			initGood(glVertexSource, glFragmentSource);
	}

	/** Processes #include directives in shader source */
	private function processIncludes(source:String):String
	{
		var includeRegex = ~/#include\s+"([^"]+)"/;
		while (includeRegex.match(source))
		{
			var includePath = includeRegex.matched(1);
			var includeContent = "";
			includeContent = sys.io.File.getContent(includePath);
			source = includeRegex.replace(source, includeContent);
		}
		return source;
	}

	/** Validates shader compilation */
	private function validateShader(gl:Dynamic, shader:Dynamic, source:String, type:String):Bool
	{
		if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS))
		{
			var log = gl.getShaderInfoLog(shader);
			if (DEBUG)
			{
				trace('$type Shader Error:');
				trace(log);
				trace('Source:');
				trace(source);
			}
			return false;
		}
		return true;
	}

	/** Validates program linking */
	private function validateProgram(gl:Dynamic, program:Dynamic):Bool
	{
		gl.validateProgram(program);
		if (!gl.getProgramParameter(program, gl.VALIDATE_STATUS))
		{
			var log = gl.getProgramInfoLog(program);
			if (DEBUG)
				trace('Program Validation Error: $log');
			return false;
		}
		return true;
	}

	/** Initialize shader with modern GLSL version */
	public function initGood(glVertexSource:String, glFragmentSource:String)
	{
		@:privateAccess
		var gl = __context.gl;

		#if android
		var prefix = "#version 300 es\n";
		#elseif (js && html5)
		var prefix = "#version 300 es\n";
		#else
		var prefix = "#version 140\n";
		#end

		#if (js && html5)
		prefix += (precisionHint == FULL ? "precision mediump float;\n" : "precision lowp float;\n");
		#else
		prefix += "#ifdef GL_ES\n"
			+ (precisionHint == FULL ? "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
				+ "precision highp float;\n"
				+ "#else\n"
				+ "precision mediump float;\n"
				+ "#endif\n" : "precision lowp float;\n")
			+ "#endif\n\n";
		#end

		var vertex = processIncludes(glVertexSource);
		var fragment = processIncludes(glFragmentSource);

		#if android
		prefix += 'out vec4 output_FragColor;\n';
		vertex = prefix + vertex.replace("attribute", "in").replace("varying", "out");
		fragment = prefix + fragment.replace("varying", "in").replace("texture2D", "texture").replace("gl_FragColor", "output_FragColor");
		#else
		vertex = prefix + vertex.replace("attribute", "in").replace("varying", "out");
		fragment = prefix + fragment.replace("varying", "in");
		#end

		var id = vertex + fragment;

		if (DEBUG)
			trace('Compiling ${custom ? "custom" : "default"} shader...');
		@:privateAccess
		if (__context.__programs.exists(id) && save)
		{
			@:privateAccess
			program = __context.__programs.get(id);
			if (DEBUG)
				trace("Using cached program");
		}
		else
		{
			program = __context.createProgram(GLSL);

			var vs = gl.createShader(gl.VERTEX_SHADER);
			gl.shaderSource(vs, vertex);
			gl.compileShader(vs);
			if (!validateShader(gl, vs, vertex, "Vertex"))
			{
				gl.deleteShader(vs);
				return;
			}

			var fs = gl.createShader(gl.FRAGMENT_SHADER);
			gl.shaderSource(fs, fragment);
			gl.compileShader(fs);
			if (!validateShader(gl, fs, fragment, "Fragment"))
			{
				gl.deleteShader(vs);
				gl.deleteShader(fs);
				return;
			}

			@:privateAccess
			var glProgram = program.__glProgram = gl.createProgram();
			gl.attachShader(glProgram, vs);
			gl.attachShader(glProgram, fs);
			gl.linkProgram(glProgram);

			gl.deleteShader(vs);
			gl.deleteShader(fs);

			if (!gl.getProgramParameter(glProgram, gl.LINK_STATUS))
			{
				var log = gl.getProgramInfoLog(glProgram);
				if (DEBUG)
					trace('Link Error: $log');
				gl.deleteProgram(glProgram);
				return;
			}

			if (!validateProgram(gl, glProgram))
			{
				gl.deleteProgram(glProgram);
				return;
			}
			@:privateAccess
			if (save)
			{
				__context.__programs.set(id, program);
				programCache.set(id, {
					program: program,
					timestamp: Timer.stamp()
				});
			}

			if (DEBUG)
				trace("Program compiled successfully");
		}

		if (DEBUG)
		{
			var cacheSize = Lambda.count(programCache);
			trace('Cache status: $cacheSize shaders stored');
			if (cacheSize > MAX_CACHE_SIZE * 0.8)
				trace('Warning: Cache is getting full ($cacheSize/${MAX_CACHE_SIZE})');
		}

		if (program != null)
		{
			@:privateAccess
			glProgram = program.__glProgram;
			bindParameters();
		}
	}

	/** Bind shader parameters after program initialization */
	private function bindParameters():Void
	{
		@:privateAccess
		var gl = __context.gl;

		for (input in __inputBitmapData)
		{
			@:privateAccess
			if (input.__isUniform)
			{
				@:privateAccess
				input.index = gl.getUniformLocation(glProgram, input.name);
			}
			else
			{
				@:privateAccess
				input.index = gl.getAttribLocation(glProgram, input.name);
			}
		}

		for (parameter in __paramBool)
		{
			@:privateAccess
			if (parameter.__isUniform)
			{
				@:privateAccess
				parameter.index = gl.getUniformLocation(glProgram, parameter.name);
			}
			else
			{
				@:privateAccess
				parameter.index = gl.getAttribLocation(glProgram, parameter.name);
			}
		}

		for (parameter in __paramFloat)
		{
			@:privateAccess
			if (parameter.__isUniform)
			{
				@:privateAccess
				parameter.index = gl.getUniformLocation(glProgram, parameter.name);
			}
			else
			{
				@:privateAccess
				parameter.index = gl.getAttribLocation(glProgram, parameter.name);
			}
		}

		for (parameter in __paramInt)
		{
			@:privateAccess
			if (parameter.__isUniform)
			{
				@:privateAccess
				parameter.index = gl.getUniformLocation(glProgram, parameter.name);
			}
			else
			{
				@:privateAccess
				parameter.index = gl.getAttribLocation(glProgram, parameter.name);
			}
		}
	}

	#if debug
	/** Check for potential memory leaks in shader cache */
	public function checkMemoryLeaks():Void
	{
		trace('Cache size: ${Lambda.count(programCache)}');
		for (id => program in programCache)
			trace('Program age: ${Timer.stamp() - program.timestamp}s');
	}
	#end
}

/** Type definition for cached program data */
private typedef CachedProgram =
{
	program:Dynamic,
	timestamp:Float
}
