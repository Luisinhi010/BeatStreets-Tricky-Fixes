package;

import flixel.graphics.frames.FlxAtlasFrames;
import openfl.filters.BitmapFilterQuality;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.BlurFilter;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
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
import openfl.display.BlendMode;

/**
 * FlxSprite subclass that adds advanced 3D transformation.
 * This sprite supports:
 * - 3D transformations (position, rotation, perspective)
 * - Smooth transitions using tweens
 */
class CustomSprite extends FlxSprite
{
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

	/** Oversampling quality (1 = normal, 2 = 2x, 4 = 4x etc) */
	public var oversampleQuality:Int = 1;

	/** Glow color */
	public var glowColor:FlxColor = FlxColor.TRANSPARENT;

	/** Glow alpha */
	public var glowAlpha:Float = 0.5;

	/** Glow radius */
	public var glowRadius:Float = 10;

	/** If true, enables oversampling */
	public var enableOversampling:Bool = false;

	/** If true, enables glow effect */
	public var enableGlow:Bool = false;

	/** Internal buffer for oversampling */
	private var oversampledBuffer:BitmapData;

	/** Internal buffer for glow */
	private var glowBuffer:BitmapData;

	private var is3DMode:Bool = false;
	private var useEffects:Bool = false;
	private var bufferValid:Bool = false;

	/**
	 * 
	 * @param X The initial X position of the sprite.
	 * @param Y The initial Y position of the sprite.
	 */
	public function new(X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		enable3D = true;
		visible = true;
		alpha = 1;
	}

	override function initVars()
	{
		super.initVars();

		// Garantir que os buffers são nulos inicialmente
		oversampledBuffer = null;
		glowBuffer = null;

		// Inicializar valores padrão
		enableOversampling = false;
		enableGlow = false;
		oversampleQuality = 1;
		glowColor = FlxColor.TRANSPARENT;
		glowAlpha = 0.5;
		glowRadius = 10;
		is3DMode = false;
		useEffects = false;
		bufferValid = false;

		if (enable3D)
		{
			_matrix3D = new Matrix3D();
			_position3D = new Vector3D();
			updateCenter();
		}
	}

	function updateCenter()
	{
		centerX = width * 0.5;
		centerY = height * 0.5;
		centerZ = focalLength * 0.5;
	}

	override public function destroy():Void
	{
		if (oversampledBuffer != null)
		{
			oversampledBuffer.dispose();
			oversampledBuffer = null;
		}

		if (glowBuffer != null)
		{
			glowBuffer.dispose();
			glowBuffer = null;
		}

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

		is3DMode = false;
		bufferValid = false;

		super.destroy();
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		if (enable3D)
			draw3D(camera);
		else
			super.drawComplex(camera);
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

	override public function draw():Void
	{
		if (useEffects)
			drawWithEffects();
		else
			super.draw();
	}

	private function validateBuffers():Bool
	{
		if (graphic == null || _frame == null)
			return false;

		var newWidth = Std.int(_frame.sourceSize.x);
		var newHeight = Std.int(_frame.sourceSize.y);

		if (newWidth <= 0 || newHeight <= 0)
			return false;

		if (framePixels == null || framePixels.width != newWidth || framePixels.height != newHeight)
		{
			if (framePixels != null)
				framePixels.dispose();
			framePixels = new BitmapData(newWidth, newHeight, true, FlxColor.TRANSPARENT);
			bufferValid = false;
		}

		if (!bufferValid)
		{
			framePixels.fillRect(framePixels.rect, FlxColor.TRANSPARENT);
			_frame.paint(framePixels, new Point(), true);
			bufferValid = true;
		}

		return true;
	}

	private function drawWithEffects():Void
	{
		var originalPixels = framePixels.clone();

		if (enableOversampling && oversampleQuality > 1)
			applyOversampling();

		if (enableGlow && glowColor != FlxColor.TRANSPARENT)
			applyGlow();

		super.draw();

		framePixels.dispose();
		framePixels = originalPixels;
	}

	private function draw3D(camera:FlxCamera):Void
	{
		if (camera == null)
			return;

		var matrix = getMat3D();
		if (matrix == null)
			return;

		_frame.prepareMatrix(matrix, false);

		if (flipX)
			matrix.scale(-1, 1);
		if (flipY)
			matrix.scale(1, -1);

		matrix.rotate(angle * Math.PI / 180);

		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);

		applyTransform3D(matrix);

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

	private function applyOversampling():Void
	{
		if (!bufferValid)
			return;

		var w = Std.int(frameWidth * oversampleQuality);
		var h = Std.int(frameHeight * oversampleQuality);

		if (oversampledBuffer == null || oversampledBuffer.width != w || oversampledBuffer.height != h)
		{
			if (oversampledBuffer != null)
				oversampledBuffer.dispose();
			oversampledBuffer = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}

		var matrix = new Matrix();
		matrix.scale(oversampleQuality, oversampleQuality);

		oversampledBuffer.fillRect(oversampledBuffer.rect, FlxColor.TRANSPARENT);
		oversampledBuffer.draw(framePixels, matrix, null, null, null, true);

		matrix.identity();
		matrix.scale(1 / oversampleQuality, 1 / oversampleQuality);

		framePixels.draw(oversampledBuffer, matrix, null, null, null, true);
	}

	private function applyGlow():Void
	{
		if (!bufferValid)
			return;

		var padding = Math.ceil(glowRadius * 2);
		var w = Std.int(frameWidth + padding * 2);
		var h = Std.int(frameHeight + padding * 2);

		// Criar ou redimensionar o buffer do glow se necessário
		if (glowBuffer == null || glowBuffer.width != w || glowBuffer.height != h)
		{
			if (glowBuffer != null)
				glowBuffer.dispose();
			glowBuffer = new BitmapData(w, h, true, FlxColor.TRANSPARENT);
		}

		// Aplicar blur ao glow
		var blurFilter = new BlurFilter(glowRadius, glowRadius, BitmapFilterQuality.HIGH);
		var colorMatrix = new ColorMatrixFilter([
			glowColor.redFloat,                    0,                   0,         0, 0,
			                 0, glowColor.greenFloat,                   0,         0, 0,
			                 0,                    0, glowColor.blueFloat,         0, 0,
			                 0,                    0,                   0, glowAlpha, 0
		]);

		// Aplicar os filtros
		var matrix = new Matrix();
		matrix.translate(padding, padding);

		glowBuffer.fillRect(glowBuffer.rect, FlxColor.TRANSPARENT);
		glowBuffer.draw(framePixels, matrix);
		glowBuffer.applyFilter(glowBuffer, glowBuffer.rect, new Point(), blurFilter);
		glowBuffer.applyFilter(glowBuffer, glowBuffer.rect, new Point(), colorMatrix);

		// Renderizar o glow abaixo do sprite original
		var finalMatrix = new Matrix();
		finalMatrix.translate(-padding, -padding);
		framePixels.draw(glowBuffer, finalMatrix, null, SCREEN);
	}

	/**
	 * Sets up glow effect
	 * @param color Glow color
	 * @param alpha Glow alpha (0-1)
	 * @param radius Glow radius in pixels
	 */
	public function setGlow(color:FlxColor, alpha:Float = 0.5, radius:Float = 10):Void
	{
		if (graphic == null || frames == null)
		{
			trace("Warning: Cannot set glow - sprite not initialized");
			return;
		}

		glowColor = color;
		glowAlpha = alpha;
		glowRadius = radius;
		enableGlow = true;
		useEffects = true;
	}

	/**
	 * Removes glow effect
	 */
	public function removeGlow():Void
	{
		enableGlow = false;
		glowColor = FlxColor.TRANSPARENT;
	}

	/**
	 * Sets oversampling quality
	 * @param quality Oversampling multiplier (1 = normal, 2 = 2x, 4 = 4x etc)
	 */
	public function setOversampling(quality:Int):Void
	{
		if (graphic == null || frames == null)
		{
			trace("Warning: Cannot set oversampling - sprite not initialized");
			return;
		}

		oversampleQuality = Std.int(FlxMath.bound(quality, 1, 8));
		enableOversampling = quality > 1;
		useEffects = enableOversampling;
	}

	public function setEffects(useEffects:Bool):Void
	{
		this.useEffects = useEffects;
		if (!useEffects)
		{
			// Limpar buffers
			if (oversampledBuffer != null)
			{
				oversampledBuffer.dispose();
				oversampledBuffer = null;
			}
			if (glowBuffer != null)
			{
				glowBuffer.dispose();
				glowBuffer = null;
			}
		}
	}
}
