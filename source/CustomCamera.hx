package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import openfl.geom.Rectangle;

/**
 * Specialized camera with corrections for rotation and resizing.
 */
class CustomCamera extends FlxCamera
{
	// Downscroll settings
	public var downscroll(default, set):Bool = false;

	private var originalScrollY:Float = 0;

	// Rotation compensation
	private var _lastAngle:Float = 0;
	private var _rotationBuffer:Float = 1.0;
	private var _originalWidth:Int = 0;
	private var _originalHeight:Int = 0;
	private var _isResizing:Bool = false;

	// Window size references
	private var _lastWindowWidth:Int = 0;
	private var _lastWindowHeight:Int = 0;

	// Framerate control
	private var targetFramerate:Float = 0;
	private var frameTimer:Float = 0;
	private var frameInterval:Float = 0;
	private var lastFrameTime:Float = 0;

	public function new(x:Float = 0, y:Float = 0, width:Int = 0, height:Int = 0, zoom:Float = 0, downscroll:Bool = false)
	{
		_originalWidth = width <= 0 ? Math.ceil(FlxG.width) : width;
		_originalHeight = height <= 0 ? Math.ceil(FlxG.height) : height;

		super(x, y, width, height, zoom);

		this.downscroll = downscroll;

		// Stores the initial window size
		_lastWindowWidth = FlxG.width;
		_lastWindowHeight = FlxG.height;

		// Fixes the flashSprite to allow rotation without cutting
		applyRotationFix();
	}

	function set_downscroll(value:Bool):Bool
	{
		if (downscroll != value)
		{
			downscroll = value;

			if (downscroll)
				scroll.y = -scroll.y + height;
			else
				scroll.y = originalScrollY;

			if (target != null)
				snapToTarget();
		}

		return downscroll;
	}

	override public function update(elapsed:Float):Void
	{
		// If there is a specific framerate
		if (frameInterval > 0)
		{
			frameTimer += elapsed;

			if (frameTimer >= frameInterval)
			{
				var adjustedElapsed = frameTimer;
				frameTimer = 0;
				lastFrameTime = adjustedElapsed;

				updateCamera(adjustedElapsed);
			}
		}
		else
		{
			// Normal update
			updateCamera(elapsed);
		}
	}

	/**
	 * Sets a specific framerate for this camera, different from the game's framerate.
	 * Useful for effects like slow-motion or lag simulation.
	 * 
	 * @param fps Desired framerate. Use 0 to disable and use the game's framerate.
	 */
	public function setFramerate(fps:Float):Void
	{
		targetFramerate = fps;

		if (fps <= 0) // Disables custom framerate control
			frameInterval = 0;
		else // Sets the interval between frames
			frameInterval = 1 / fps;

		frameTimer = 0;
		lastFrameTime = 0;
	}

	/**
	 * Updates the camera with the adjusted elapsed time.
	 */
	private function updateCamera(elapsed:Float):Void
	{
		if (_lastWindowWidth != FlxG.width || _lastWindowHeight != FlxG.height)
			handleWindowResize();

		if (_lastAngle != angle)
		{
			applyRotationFix();
			_lastAngle = angle;
		}

		originalScrollY = scroll.y;
		super.update(elapsed);

		if (downscroll && target != null)
		{
			var targetPos = FlxPoint.get();
			target.getMidpoint(targetPos);
			scroll.y = -(scroll.y + height) + height;
			targetPos.put();
		}
	}

	private function applyRotationFix():Void
	{
		var absAngle = Math.abs(angle % 90);
		if (absAngle > 45)
			absAngle = 90 - absAngle;

		var angleRadians = absAngle * Math.PI / 180;
		var sinAngle = FlxMath.fastSin(angleRadians);
		var cosAngle = FlxMath.fastCos(angleRadians);

		var bufferFactor = Math.max((width * cosAngle + height * sinAngle) / width, (width * sinAngle + height * cosAngle) / height);

		_rotationBuffer = bufferFactor;

		if (FlxG.renderBlit)
		{
			if (_flashBitmap != null)
			{
				_flashBitmap.x = -(_flashBitmap.width * (_rotationBuffer - 1) / 2);
				_flashBitmap.y = -(_flashBitmap.height * (_rotationBuffer - 1) / 2);
			}
		}
		else
		{
			if (canvas != null)
				updateInternalSpritePositions();
		}

		updateRotatedScrollRect();
	}

	private function updateRotatedScrollRect():Void
	{
		if (_scrollRect != null && _scrollRect.scrollRect != null)
		{
			var rect = _scrollRect.scrollRect;

			var scaleX = initialZoom * FlxG.scaleMode.scale.x;
			var scaleY = initialZoom * FlxG.scaleMode.scale.y;

			var expandedWidth = width * scaleX * _rotationBuffer;
			var expandedHeight = height * scaleY * _rotationBuffer;

			rect.width = expandedWidth;
			rect.height = expandedHeight;

			rect.x = -((expandedWidth - width * scaleX) * 0.5);
			rect.y = -((expandedHeight - height * scaleY) * 0.5);

			_scrollRect.scrollRect = rect;

			_scrollRect.x = -rect.width * 0.5;
			_scrollRect.y = -rect.height * 0.5;
		}
	}

	private function handleWindowResize():Void
	{
		if (_isResizing)
			return;

		_isResizing = true;

		var windowRatio = FlxG.width / FlxG.height;
		var cameraRatio = _originalWidth / _originalHeight;

		var newWidth:Int;
		var newHeight:Int;

		if (windowRatio > cameraRatio)
		{
			newHeight = FlxG.height;
			newWidth = Std.int(newHeight * cameraRatio + 0.5); // +0.5 para arredondar corretamente
		}
		else
		{
			newWidth = FlxG.width;
			newHeight = Std.int(newWidth / cameraRatio + 0.5);
		}

		x = (FlxG.width - newWidth) / 2;
		y = (FlxG.height - newHeight) / 2;

		setSize(newWidth, newHeight);

		_lastWindowWidth = FlxG.width;
		_lastWindowHeight = FlxG.height;

		applyRotationFix();

		_isResizing = false;
	}

	override public function onResize():Void
	{
		super.onResize();
		handleWindowResize();
	}

	override function updateScrollRect():Void
	{
		super.updateScrollRect();

		if (angle != 0)
		{
			updateRotatedScrollRect();
		}
	}

	override function updateInternalSpritePositions():Void
	{
		super.updateInternalSpritePositions();

		if (angle != 0 && !FlxG.renderBlit && canvas != null)
		{
			var extraSpace = ((_rotationBuffer - 1) / 2);
			var offsetX = width * extraSpace * totalScaleX;
			var offsetY = height * extraSpace * totalScaleY;

			canvas.x -= offsetX;
			canvas.y -= offsetY;

			#if FLX_DEBUG
			if (debugLayer != null)
			{
				debugLayer.x = canvas.x;
				debugLayer.y = canvas.y;
			}
			#end
		}
	}

	override function set_angle(Value:Float):Float
	{
		var result = super.set_angle(Value);

		if (result != 0 && _lastAngle != result)
		{
			applyRotationFix();
			_lastAngle = result;
		}

		return result;
	}
}
