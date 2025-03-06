package;

import openfl.Vector;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.ShaderParameter;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.animation.FlxAnimation;
import haxe.ds.Map;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMatrix;

/**
 * FlxSprite subclass that adds advanced 3D transformation and camera following capabilities.
 * This sprite supports:
 * - 3D transformations (position, rotation, perspective)
 * - Camera following based on animation frames
 * - Smooth transitions using tweens
 * - Frame-based bounds caching for optimization
 */
class CustomSprite extends FlxSprite
{
	/**
	 * Map of cameras that are following this sprite's animations
	 */
	private var followingCameras:Map<FlxCamera, FollowData>;

	/**
	 * Cache for frame bounds to optimize camera following
	 */
	private var frameBounds:Map<String, FlxRect>;

	/**
	 * If true, cameras will follow animation frames' bounds
	 */
	public var cameraFollowsAnimation:Bool = false;

	/**
	 * Camera follow offset for animations
	 */
	public var cameraOffset:FlxPoint;

	/**
	 * How smooth the camera follows animations (0-1)
	 */
	public var cameraLerpStrength:Float = 0.1;

	// 3D properties
	public var x3D(default, set):Float = 0;
	public var y3D(default, set):Float = 0;
	public var z3D(default, set):Float = 0;
	public var rotationX(default, set):Float = 0;
	public var rotationY(default, set):Float = 0;
	public var rotationZ(default, set):Float = 0;

	// 3D matrix and projection
	private var _matrix3D:Matrix3D;
	private var _position3D:Vector3D;

	/** If the sprite uses 3D transformation */
	public var enable3D:Bool = true;

	/** Focal length for perspective calculations */
	public var focalLength:Float = 1000;

	/** 3D rotation center */
	public var centerX(default, null):Float = 0;

	public var centerY(default, null):Float = 0;
	public var centerZ(default, null):Float = 0;

	private var _rotationTween:FlxTween;
	private var _positionTween:FlxTween;

	/**
	 * Creates a new CustomSprite with 3D and camera following capabilities.
	 * 
	 * @param X The initial X position of the sprite.
	 * @param Y The initial Y position of the sprite.
	 */
	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);
		followingCameras = new Map();
		frameBounds = new Map();
		cameraOffset = FlxPoint.get(0, 0);
	}

	override function initVars()
	{
		super.initVars();

		_matrix3D = new Matrix3D();
		_position3D = new Vector3D();
		updateCenter();
	}

	function updateCenter()
	{
		centerX = width * 0.5;
		centerY = height * 0.5;
		centerZ = focalLength * 0.5;
	}

	/**
	 * Makes a camera follow this sprite's animation frames with optional offset.
	 * The camera will smoothly follow the sprite's movements and animations.
	 * 
	 * @param camera The FlxCamera to attach to this sprite.
	 * @param offset Optional offset point for the camera's position.
	 */
	public function addCameraFollow(camera:FlxCamera, ?offset:FlxPoint):Void
	{
		if (!followingCameras.exists(camera))
		{
			followingCameras.set(camera, {
				offset: offset != null ? offset : FlxPoint.get(),
				lastPosition: FlxPoint.get(x, y)
			});
		}
	}

	/**
	 * Stops a camera from following this sprite's animation
	 */
	public function removeCameraFollow(camera:FlxCamera):Void
	{
		if (followingCameras.exists(camera))
		{
			var data = followingCameras.get(camera);
			data.offset.put();
			data.lastPosition.put();
			followingCameras.remove(camera);
		}
	}

	/**
	 * Caches the bounds of a frame for faster camera following
	 */
	private function cacheFrameBounds(frameId:String):FlxRect
	{
		if (!frameBounds.exists(frameId))
		{
			var bounds = FlxRect.get();
			if (frames != null)
			{
				var frame = frames.framesHash.get(frameId);
				if (frame != null)
				{
					bounds.set(frame.offset.x * scale.x, frame.offset.y * scale.y, frame.sourceSize.x * scale.x, frame.sourceSize.y * scale.y);
				}
			}
			frameBounds.set(frameId, bounds);
		}
		return frameBounds.get(frameId);
	}

	override public function update(elapsed:Float):Void
	{
		try
		{
			super.update(elapsed);

			if (cameraFollowsAnimation && animation.curAnim != null)
			{
				var curFrameName = animation.curAnim.name + animation.curAnim.curFrame;
				var frameBounds = cacheFrameBounds(curFrameName);

				for (camera => data in followingCameras)
				{
					var halfWidth = frameBounds.width * 0.5;
					var halfHeight = frameBounds.height * 0.5;

					var targetX = x + frameBounds.x + halfWidth + data.offset.x + cameraOffset.x;
					var targetY = y + frameBounds.y + halfHeight + data.offset.y + cameraOffset.y;

					var camHalfWidth = camera.width * 0.5;
					var camHalfHeight = camera.height * 0.5;

					camera.scroll.x += (targetX - camera.scroll.x - camHalfWidth) * cameraLerpStrength;
					camera.scroll.y += (targetY - camera.scroll.y - camHalfHeight) * cameraLerpStrength;

					data.lastPosition.set(targetX, targetY);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Update error: $e');
			throw 'Update error: $e';
		}
	}

	override public function destroy():Void
	{
		try
		{
			// Cleanup

			for (camera => data in followingCameras)
			{
				data.offset.put();
				data.lastPosition.put();
			}
			followingCameras = null;

			for (bounds in frameBounds)
			{
				bounds.put();
			}
			frameBounds = null;

			cameraOffset.put();
			cameraOffset = null;

			if (_rotationTween != null)
			{
				_rotationTween.cancel();
				_rotationTween = null;
			}

			if (_positionTween != null)
			{
				_positionTween.cancel();
				_positionTween = null;
			}

			_matrix3D = null;
			_position3D = null;

			super.destroy();
		}
		catch (e:Dynamic)
		{
			trace('Destroy error: $e');
			throw 'Destroy error: $e';
		}
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		if (!enable3D)
		{
			super.drawComplex(camera);
			return;
		}

		try
		{
			var matrix = getMat3D();

			// Prepare frame matrix
			_frame.prepareMatrix(matrix);
			if (flipX)
				matrix.scale(-1, 1);
			if (flipY)
				matrix.scale(1, -1);

			matrix.translate(-origin.x, -origin.y);
			matrix.scale(scale.x, scale.y);

			// Apply 3D transform
			applyTransform3D(matrix);

			// Position on screen
			var pos = getScreenPosition(_point, camera);
			pos.subtract(offset.x, offset.y);
			pos.add(origin.x, origin.y);
			matrix.translate(pos.x, pos.y);

			if (isPixelPerfectRender(camera))
			{
				matrix.tx = Math.floor(matrix.tx);
				matrix.ty = Math.floor(matrix.ty);
			}

			camera.drawPixels(_frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
		}
		catch (e:Dynamic)
		{
			trace('3D render error: $e');
			throw '3D render error: $e';
		}
	}

	private function getMat3D():FlxMatrix
	{
		var matrix = new FlxMatrix();

		var halfWidth = width * 0.5;
		var halfHeight = height * 0.5;

		// Mover para a origem (centro do sprite)
		matrix.translate(-halfWidth, -halfHeight);

		if (rotationX != 0)
		{
			var radX = rotationX * Math.PI / 180;
			var scaleY = FlxMath.fastCos(radX);
			matrix.scale(1, scaleY);
		}

		if (rotationY != 0)
		{
			var radY = rotationY * Math.PI / 180;
			var scaleX = FlxMath.fastCos(radY);
			matrix.scale(scaleX, 1);
		}

		if (rotationZ != 0)
		{
			var radZ = rotationZ * Math.PI / 180;
			var cosZ = FlxMath.fastCos(radZ);
			var sinZ = FlxMath.fastSin(radZ);
			matrix.rotateWithTrig(cosZ, sinZ);
		}

		// Voltar à posição original
		matrix.translate(halfWidth, halfHeight);

		// Aplicar posição 3D
		matrix.translate(x3D, y3D);

		var perspective = focalLength / (focalLength + z3D);
		matrix.scale(perspective, perspective);

		return matrix;
	}

	private function applyTransform3D(matrix:FlxMatrix):Void
	{
		if (!enable3D)
			return;

		var matrix3D = new Matrix3D();
		var rad2deg = Math.PI / 180;

		var rotationMatrix = new Matrix3D();

		var cosX = FlxMath.fastCos(rotationX * rad2deg);
		var sinX = FlxMath.fastSin(rotationX * rad2deg);
		rotationMatrix.rawData = Vector.ofArray([
			1.0,  0.0,   0.0, 0.0,
			0.0, cosX, -sinX, 0.0,
			0.0, sinX,  cosX, 0.0,
			0.0,  0.0,   0.0, 1.0
		]);
		matrix3D.append(rotationMatrix);

		var cosY = FlxMath.fastCos(rotationY * rad2deg);
		var sinY = FlxMath.fastSin(rotationY * rad2deg);
		rotationMatrix.rawData = Vector.ofArray([
			 cosY, 0.0, sinY, 0.0,
			  0.0, 1.0,  0.0, 0.0,
			-sinY, 0.0, cosY, 0.0,
			  0.0, 0.0,  0.0, 1.0
		]);
		matrix3D.append(rotationMatrix);

		var cosZ = FlxMath.fastCos(rotationZ * rad2deg);
		var sinZ = FlxMath.fastSin(rotationZ * rad2deg);
		rotationMatrix.rawData = Vector.ofArray([
			cosZ, -sinZ, 0.0, 0.0,
			sinZ,  cosZ, 0.0, 0.0,
			 0.0,   0.0, 1.0, 0.0,
			 0.0,   0.0, 0.0, 1.0
		]);
		matrix3D.append(rotationMatrix);

		var rawData = matrix3D.rawData;
		var newMatrix = new FlxMatrix(rawData[0], rawData[1], rawData[4], rawData[5], rawData[12], rawData[13]);

		// Aplicar à matriz original
		matrix.concat(newMatrix);
	}

	private function updateSprite3D():Void
	{
		if (!enable3D)
			return;

		var perspective = focalLength / (focalLength + z3D);
		var halfWidth = width * 0.5;
		var halfHeight = height * 0.5;

		x = x3D + (halfWidth * (1 - perspective));
		y = y3D + (halfHeight * (1 - perspective));

		alpha = FlxMath.bound(1 - (z3D / (focalLength * 2)), 0, 1);
	}

	// Setters for 3D properties
	function set_x3D(value:Float):Float
	{
		x3D = value;
		if (enable3D)
			updateSprite3D();
		return value;
	}

	function set_y3D(value:Float):Float
	{
		y3D = value;
		if (enable3D)
			updateSprite3D();
		return value;
	}

	function set_z3D(value:Float):Float
	{
		z3D = value;
		if (enable3D)
			updateSprite3D();
		return value;
	}

	function set_rotationX(value:Float):Float
	{
		rotationX = value % 360;
		if (enable3D)
			updateSprite3D();
		return rotationX;
	}

	function set_rotationY(value:Float):Float
	{
		rotationY = value % 360;
		if (enable3D)
			updateSprite3D();
		return rotationY;
	}

	function set_rotationZ(value:Float):Float
	{
		rotationZ = value % 360;
		if (enable3D)
			updateSprite3D();
		return rotationZ;
	}

	/**
	 * Sets the 3D position of the sprite with perspective transformation.
	 * Updates the sprite's 2D position based on the 3D coordinates and focal length.
	 * 
	 * @param x The X position in 3D space.
	 * @param y The Y position in 3D space.
	 * @param z The Z position in 3D space (depth).
	 */
	public function setPosition3D(x:Float, y:Float, z:Float):Void
	{
		var updateNeeded = (x3D != x || y3D != y || z3D != z);

		x3D = x;
		y3D = y;
		z3D = z;

		if (enable3D && updateNeeded)
			updateSprite3D();
	}

	/**
	 * Sets the 3D rotation angles of the sprite.
	 * Applies rotation around all three axes (X, Y, Z) with perspective.
	 * 
	 * @param rx The rotation around the X axis (pitch) in degrees.
	 * @param ry The rotation around the Y axis (yaw) in degrees.
	 * @param rz The rotation around the Z axis (roll) in degrees.
	 */
	public function setRotation3D(rx:Float, ry:Float, rz:Float):Void
	{
		rotationX = rx;
		rotationY = ry;
		rotationZ = rz;
		updateSprite3D();
	}

	/**
	 * Smoothly tweens the sprite's 3D position over time.
	 * 
	 * @param x Target X position in 3D space.
	 * @param y Target Y position in 3D space.
	 * @param z Target Z position in 3D space.
	 * @param duration Time in seconds for the tween to complete.
	 * @param ease Optional easing function.
	 */
	public function tweenPosition3D(x:Float, y:Float, z:Float, duration:Float = 1.0, ?ease:Float->Float):Void
	{
		if (_positionTween != null)
			_positionTween.cancel();

		_positionTween = FlxTween.tween(this, {
			x3D: x,
			y3D: y,
			z3D: z
		}, duration, {
			ease: ease != null ? ease : FlxEase.quartOut,
			onUpdate: function(_)
			{
				updateSprite3D();
			}
		});
	}

	/**
	 * Smoothly tweens the sprite's 3D rotation over time.
	 * 
	 * @param rx Target X rotation in degrees.
	 * @param ry Target Y rotation in degrees.
	 * @param rz Target Z rotation in degrees.
	 * @param duration Time in seconds for the tween to complete.
	 * @param ease Optional easing function.
	 */
	public function tweenRotation3D(rx:Float, ry:Float, rz:Float, duration:Float = 1.0, ?ease:Float->Float):Void
	{
		if (_rotationTween != null)
			_rotationTween.cancel();

		_rotationTween = FlxTween.tween(this, {
			rotationX: rx,
			rotationY: ry,
			rotationZ: rz
		}, duration, {
			ease: ease != null ? ease : FlxEase.quartOut,
			onUpdate: function(_)
			{
				updateSprite3D();
			}
		});
	}

	/**
	 * Debug function to print the current state of the sprite
	 */
	public function debugState():Void
	{
		trace('CustomSprite Debug State:');
		trace('Position: (' + x + ', ' + y + ')');
		trace('Scale: (' + scale.x + ', ' + scale.y + ')');
		trace('Rotation: (' + rotationX + ', ' + rotationY + ', ' + rotationZ + ')');
		trace('3D Position: (' + x3D + ', ' + y3D + ', ' + z3D + ')');
		trace('Focal Length: ' + focalLength);
	}

	public function setOpacity(value:Float):Void
	{
		this.alpha = FlxMath.bound(value, 0, 1);
	}
}

private typedef FollowData =
{
	offset:FlxPoint,
	lastPosition:FlxPoint
}
