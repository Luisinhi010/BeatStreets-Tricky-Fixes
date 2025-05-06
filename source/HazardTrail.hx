import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxGraphicAsset;
import lime.math.Vector2;

/**
 * A trail effect inspired by Geometry Dash that follows a sprite.
 * This implementation is framerate independent.
 */
class HazardTrail extends FlxSprite
{
	// detail refers to how many points should be saved. More points also means a longer trail.
	public var detail:Int = 32;

	// The minimum detail allowed to prevent array issues
	public var minDetail:Int = 2;

	// Fade multiplier for the trail (0-1)
	public var fadeMultiplier:Float = 1.0;

	// width in pixels
	public var trailWidth:Float = 64;

	// Copy parent properties
	public var copyParentAlpha:Bool = true;
	public var copyParentColor:Bool = true;
	public var copyParentShader:Bool = true;

	// Trail positioning
	public var pointOffsetX:Float = 0;
	public var pointOffsetY:Float = 0;
	public var tryToCenterOnParent:Bool = true;

	// Update delay in seconds
	public var updateDelay:Float = 0.012;

	// The current parent sprite
	public var parent:FlxSprite;

	/**
	 * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
	 */
	var vertices:DrawData<Float> = new DrawData<Float>();

	/**
	 * A `Vector` of integers or indexes, where every three indexes define a triangle.
	 */
	var indices:DrawData<Int> = new DrawData<Int>();

	/**
	 * A `Vector` of normalized coordinates used to apply texture mapping.
	 */
	var uvtData:DrawData<Float> = new DrawData<Float>();

	var pointsX:Array<Float> = [];
	var pointsY:Array<Float> = [];

	// Time tracking
	var totalTime:Float = 0;
	var lastUpdateTime:Float = 0;

	public function new(Parent:FlxSprite, simpleGraphic:FlxGraphicAsset)
	{
		this.parent = Parent;
		super(0, 0, simpleGraphic);
		detail = Std.int(Math.max(detail, minDetail));
		fadeMultiplier = Math.max(0, Math.min(fadeMultiplier, 1));
		resetTrail();
	}

	override function update(elapsed:Float):Void
	{
		if (parent == null || !parent.exists)
		{
			visible = false;
			return;
		}

		super.update(elapsed);
		totalTime += elapsed;

		if (parent != null)
		{
			if (copyParentAlpha)
			{
				// Apply a gradual fade based on the point's position in the trail
				var baseAlpha = parent.alpha * fadeMultiplier;
				alpha = baseAlpha;
				// If the parent is invisible, the trail should also be invisible
				visible = parent.visible && baseAlpha > 0;
			}

			if (copyParentColor)
				color = parent.color;

			// Check for parent death
			if (!parent.alive)
				destroy();
		}

		if (totalTime - lastUpdateTime >= updateDelay)
		{
			detail = Std.int(Math.max(detail, minDetail));
			if (!Math.isNaN(parent.x) && !Math.isNaN(parent.y))
			{
				updatePosArray();
				updateTris();
			}
			lastUpdateTime = totalTime;
		}
	}

	var curAngle:Float = 0;

	public function updatePosArray()
	{
		if (parent == null || !parent.exists)
			return;

		var pX:Float = parent.x;
		var pY:Float = parent.y;

		if (tryToCenterOnParent)
		{
			pX += parent.width * 0.5;
			pY += parent.height * 0.5;
		}

		pX += pointOffsetX;
		pY += pointOffsetY;

		// Add latest to start and pushes the rest up by one
		pointsX.unshift(pX);
		pointsY.unshift(pY);

		// remove the last one as anything past this point won't be used and is a waste of memory
		while (pointsX.length > detail)
		{
			pointsX.pop();
			pointsY.pop();
		}

		// Ensure arrays have same length for safety
		while (pointsX.length > pointsY.length)
			pointsX.pop();
		while (pointsY.length > pointsX.length)
			pointsY.pop();
	}

	public function updateTris()
	{
		var vertices:Array<Float> = [];
		var uvtData:Array<Float> = [];
		var noteIndices:Array<Int> = [];

		var curAmount = pointsX.length;
		if (curAmount < 1)
		{
			trace("Too little detail for trail to be constructed.");
			return;
		}

		// to keep the face normal facing towards the camera for culling support.
		var dumbAlt:Bool = true;
		for (i in 0...(curAmount * 2) - 2)
		{
			if (dumbAlt)
			{
				noteIndices.push(i + 0);
				noteIndices.push(i + 2);
				noteIndices.push(i + 1);
			}
			else
			{
				noteIndices.push(i + 0);
				noteIndices.push(i + 1);
				noteIndices.push(i + 2);
			}
			dumbAlt = !dumbAlt;
		}
		var v:Int = 0;
		for (i in 0...curAmount)
		{
			var curX:Float = pointsX[i];
			var curY:Float = pointsY[i];

			if (i + 1 < curAmount)
			{
				var nextX:Float = pointsX[i + 1];
				var nextY:Float = pointsY[i + 1];

				var angle:Float = FlxAngle.degreesFromOrigin(nextX - curX, nextY - curY);
				if (!Math.isNaN(angle))
				{
					curAngle = angle - 90;
				}
			}

			var rotateOrigin:Vector2 = new Vector2(curX, curY);
			var vert:Vector2 = rotateAround(rotateOrigin, new Vector2(curX - (trailWidth / 2), curY), curAngle);

			// Calculate fade based on position
			var fadePos:Float = i / (curAmount - 1);

			vertices[v * 2] = vert.x;
			vertices[v * 2 + 1] = vert.y;
			uvtData[v * 2] = 0;
			uvtData[v * 2 + 1] = fadePos;
			v++;

			vert = rotateAround(rotateOrigin, new Vector2(curX + (trailWidth / 2), curY), curAngle);
			vertices[v * 2] = vert.x;
			vertices[v * 2 + 1] = vert.y;
			uvtData[v * 2] = 1;
			uvtData[v * 2 + 1] = fadePos;
			v++;
		}

		this.vertices = new DrawData<Float>(vertices.length, true, vertices);
		this.indices = new DrawData<Int>(noteIndices.length, true, noteIndices);
		this.uvtData = new DrawData<Float>(uvtData.length, true, uvtData);
	}

	@:access(flixel.FlxCamera)
	override public function draw():Void
	{
		if (alpha == 0 || vertices == null || indices == null || uvtData == null || _point == null || offset == null)
		{
			return;
		}

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;
			getScreenPosition(_point, camera).subtractPoint(offset);
			camera.drawTriangles(this.graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing,
				copyParentShader ? (parent?.shader ?? null) : null);
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	override public function destroy():Void
	{
		// Proper cleanup
		if (pointsX != null)
		{
			while (pointsX.length > 0)
				pointsX.pop();
			pointsX = null;
		}
		if (pointsY != null)
		{
			while (pointsY.length > 0)
				pointsY.pop();
			pointsY = null;
		}
		vertices = null;
		indices = null;
		uvtData = null;
		parent = null;
		super.destroy();
	}

	// Reset trail data
	public function resetTrail():Void
	{
		pointsX = [];
		pointsY = [];
		totalTime = 0;
		lastUpdateTime = 0;
		curAngle = 0;
	}

	public static function rotateAround(origin:Vector2, point:Vector2, degrees:Float):Vector2
	{
		var angle:Float = degrees * (Math.PI / 180);
		var ox = origin.x;
		var oy = origin.y;
		var px = point.x;
		var py = point.y;

		var qx = ox + FlxMath.fastCos(angle) * (px - ox) - FlxMath.fastSin(angle) * (py - oy);
		var qy = oy + FlxMath.fastSin(angle) * (px - ox) + FlxMath.fastCos(angle) * (py - oy);

		return (new Vector2(qx, qy));
	}
}
