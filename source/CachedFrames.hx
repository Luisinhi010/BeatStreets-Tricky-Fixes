import flixel.sound.FlxSound;
import flixel.FlxG;
import lime.utils.Assets;
#if haxe4
import haxe.xml.Access;
#else
import haxe.xml.Fast as Access;
#end
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import Paths;

class CachedFrames
{
	public static var cachedGraphics:Map<String, FlxGraphic> = new Map();
	public static var loaded:Bool = false;
	public static var isLoading:Bool = false;

	public static function fromSparrow(id:String, xmlName:String):FlxAtlasFrames
	{
		var graphic = cachedGraphics.get(id);
		if (graphic == null)
			return null;

		var existingFrames = FlxAtlasFrames.findFrame(graphic);
		if (existingFrames != null)
			return existingFrames;

		var frames = new FlxAtlasFrames(graphic);
		var xml = Xml.parse(Assets.getText(Paths.file('images/$xmlName.xml', 'clown')));
		var data = new Access(xml.firstElement());

		for (texture in data.nodes.SubTexture)
		{
			var attributes = parseAttributes(texture);

			var rect = FlxRect.get(attributes.x, attributes.y, attributes.width, attributes.height);
			var size = attributes.trimmed ? new Rectangle(attributes.frameX, attributes.frameY, attributes.frameWidth,
				attributes.frameHeight) : new Rectangle(0, 0, rect.width, rect.height);

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);
			if (attributes.rotated && !attributes.trimmed)
				sourceSize.set(size.height, size.width);

			frames.addAtlasFrame(rect, sourceSize, offset, attributes.name, attributes.angle, attributes.flipX, attributes.flipY);
		}

		return frames;
	}

	private static function parseAttributes(texture:Access):
		{
			name:String,
			x:Float,
			y:Float,
			width:Float,
			height:Float,
			trimmed:Bool,
			rotated:Bool,
			flipX:Bool,
			flipY:Bool,
			frameX:Int,
			frameY:Int,
			frameWidth:Int,
			frameHeight:Int,
			angle:FlxFrameAngle
		}
	{
		return {
			name: texture.att.name,
			x: Std.parseFloat(texture.att.x),
			y: Std.parseFloat(texture.att.y),
			width: Std.parseFloat(texture.att.width),
			height: Std.parseFloat(texture.att.height),
			trimmed: texture.has.frameX,
			rotated: texture.has.rotated && texture.att.rotated == "true",
			flipX: texture.has.flipX && texture.att.flipX == "true",
			flipY: texture.has.flipY && texture.att.flipY == "true",
			frameX: texture.has.frameX ? Std.parseInt(texture.att.frameX) : 0,
			frameY: texture.has.frameY ? Std.parseInt(texture.att.frameY) : 0,
			frameWidth: texture.has.frameWidth ? Std.parseInt(texture.att.frameWidth) : 0,
			frameHeight: texture.has.frameHeight ? Std.parseInt(texture.att.frameHeight) : 0,
			angle: (texture.has.rotated && texture.att.rotated == "true") ? FlxFrameAngle.ANGLE_NEG_90 : FlxFrameAngle.ANGLE_0
		};
	}

	public static inline function get(id:String):FlxGraphic
		return cachedGraphics.get(id);

	public static inline function load(id:String, path:String):Void
		addToCache(id, path);

	public static function addToCache(id:String, path:String):FlxGraphic
	{
		if (cachedGraphics.exists(id))
			return cachedGraphics.get(id);

		var graph = FlxGraphic.fromAssetKey(Paths.image(path, 'clown'));
		if (graph == null)
			throw 'Failed to load graphic: $path';

		graph.persist = true;
		graph.destroyOnNoUse = false;
		cachedGraphics.set(id, graph);
		trace('Frame loaded successfully: $id');
		return graph;
	}

	public static inline function getCachedGraphic(id:String, ?path:String):FlxGraphic
		return cachedGraphics.get(id) != null ? cachedGraphics.get(id) : (path != null ? addToCache(id, path) : null);

	public static function loadFrames():Void
	{
		if (isLoading)
			return;

		isLoading = true;

		ConfigManager.init();
		loadFramesAsync();
	}

	private static function loadFramesAsync():Void
	{
		sys.thread.Thread.create(() ->
		{
			var framesConfig = ConfigManager.frameConfig;
			var framesObject:Dynamic = Reflect.field(framesConfig, "frames");
			var loadStats = loadFramesFromConfig(framesObject);

			onLoadComplete(loadStats);
		});
	}

	private static function loadFramesFromConfig(framesObject:Dynamic):{loaded:Int, total:Int}
	{
		var loadedCount = 0;
		var totalFrames = Reflect.fields(framesObject).length;

		for (field in Reflect.fields(framesObject))
		{
			if (loadSingleFrame(field, Reflect.field(framesObject, field)))
				loadedCount++;
		}

		return {loaded: loadedCount, total: totalFrames};
	}

	private static function loadSingleFrame(id:String, path:String):Bool
	{
		addToCache(id, path);
		return true;
	}

	private static function onLoadComplete(stats:{loaded:Int, total:Int})
	{
		Main.showDebugText('Loaded!');
		FlxG.sound.play(Paths.sound('complete', 'clown'), 0.5);
		FlxG.fixedTimestep = false;
		loaded = true;
		isLoading = false;
	}

	public static function clearCache()
	{
		for (graphic in cachedGraphics)
		{
			if (graphic != null)
				graphic.destroy();
		}
		cachedGraphics.clear();
		loaded = false;
		isLoading = false;
	}

	public static function reloadConfig()
	{
		clearCache();
		ConfigManager.loadFrameConfig();
		loadFrames();
	}
}
