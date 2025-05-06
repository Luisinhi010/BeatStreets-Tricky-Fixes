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
	private var _rotationBuffer:Float = 1;
	private var _originalWidth:Int = 0;
	private var _originalHeight:Int = 0;
	private var _isResizing:Bool = false;

	// Window size references
	private var _lastWindowWidth:Int = 0;
	private var _lastWindowHeight:Int = 0;

	// Framerate control
	public var targetFramerate:Float = 0;

	private var frameTimer:Float = 0;
	private var frameInterval:Float = 0;
	private var lastFrameTime:Float = 0;

	private var skipNextUpdate:Bool = false;

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
		var curElapsed:Float = elapsed;

		if (frameInterval > 0)
		{
			frameTimer += elapsed;
			if (frameTimer < frameInterval)
				return;

			curElapsed = frameTimer;
			frameTimer = 0;
			lastFrameTime = curElapsed;
		}

		updateRotation();

		super.update(curElapsed);
		updateFollowLogic(curElapsed);
	}

	private function updateFollowLogic(elapsed:Float):Void
	{
		if (_lastWindowWidth != FlxG.width || _lastWindowHeight != FlxG.height)
			handleWindowResize();

		if (_lastAngle != angle)
		{
			applyRotationFix();
			_lastAngle = angle;
		}

		originalScrollY = scroll.y;

		if (downscroll && target != null)
		{
			var targetPos = FlxPoint.get();
			target.getMidpoint(targetPos);
			scroll.y = -(scroll.y + height) + height;
			targetPos.put();
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

		if (fps <= 0)
		{
			frameInterval = 0;
			frameTimer = 0;
			lastFrameTime = 0;
			skipNextUpdate = false;
		}
		else
		{
			frameInterval = 1 / fps;
			frameTimer = 0;
			lastFrameTime = 0;
			skipNextUpdate = false;
		}
	}

	private function updateRotation():Void
	{
		if (_lastAngle != angle)
		{
			_lastAngle = angle;
			applyRotationFix();
			updateScrollRect();
			updateInternalSpritePositions();
		}
	}

	private function applyRotationFix():Void
	{
		// Reset rotation buffer
		_rotationBuffer = 1.0;

		if (angle == 0)
		{
			updateTransformation();
			return;
		}

		// Normaliza o ângulo para 0-360
		var normalizedAngle = angle % 360;
		if (normalizedAngle < 0)
			normalizedAngle += 360;

		var angleRad = normalizedAngle * Math.PI / 180;
		var cos = Math.abs(Math.cos(angleRad));
		var sin = Math.abs(Math.sin(angleRad));

		// Calcula o buffer necessário para evitar cortes
		_rotationBuffer = Math.max(Math.abs(cos) + Math.abs(sin), Math.abs(sin) + Math.abs(cos));

		updateTransformation();
	}

	private function updateTransformation():Void
	{
		if (flashSprite != null)
		{
			// Define o ponto de rotação no centro
			flashSprite.x = x * FlxG.scaleMode.scale.x + _flashOffset.x;
			flashSprite.y = y * FlxG.scaleMode.scale.y + _flashOffset.y;

			// Ajusta a origem da rotação
			_scrollRect.x = -width * 0.5 * initialZoom * FlxG.scaleMode.scale.x;
			_scrollRect.y = -height * 0.5 * initialZoom * FlxG.scaleMode.scale.y;
		}

		if (!FlxG.renderBlit && canvas != null)
		{
			var scaleFactor = (_rotationBuffer - 1) * 0.5;
			var offsetX = width * scaleFactor * totalScaleX;
			var offsetY = height * scaleFactor * totalScaleY;

			canvas.x = -offsetX;
			canvas.y = -offsetY;

			#if FLX_DEBUG
			if (debugLayer != null)
			{
				debugLayer.x = canvas.x;
				debugLayer.y = canvas.y;
			}
			#end
		}
	}

	private function updateRotatedScrollRect():Void
	{
		if (_scrollRect == null || _scrollRect.scrollRect == null)
			return;

		var rect = _scrollRect.scrollRect;
		var scaleX = initialZoom * FlxG.scaleMode.scale.x;
		var scaleY = initialZoom * FlxG.scaleMode.scale.y;

		// Calculate expanded dimensions to accommodate rotation
		var expandedWidth = width * scaleX * _rotationBuffer;
		var expandedHeight = height * scaleY * _rotationBuffer;

		// Center the expanded rect
		rect.x = -(expandedWidth - width * scaleX) * 0.5;
		rect.y = -(expandedHeight - height * scaleY) * 0.5;
		rect.width = expandedWidth;
		rect.height = expandedHeight;

		_scrollRect.scrollRect = rect;

		// Center the scrollRect sprite itself
		_scrollRect.x = -rect.width * 0.5;
		_scrollRect.y = -rect.height * 0.5;
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
			newWidth = Std.int(newHeight * cameraRatio + 0.5);
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
			updateRotatedScrollRect();
	}

	override function updateInternalSpritePositions():Void
	{
		super.updateInternalSpritePositions();

		if (angle != 0 && !FlxG.renderBlit && canvas != null)
		{
			// Calculate offsets based on rotation buffer
			var extraSpace = (_rotationBuffer - 1) * 0.5;
			var offsetX = width * extraSpace * totalScaleX;
			var offsetY = height * extraSpace * totalScaleY;

			// Apply offsets to keep content centered
			canvas.x = -offsetX;
			canvas.y = -offsetY;

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

		if (result != _lastAngle)
		{
			applyRotationFix();
			_lastAngle = result;
		}

		return result;
	}

	override function updateFlashSpritePosition():Void
	{
		if (flashSprite != null)
		{
			// Atualiza posição considerando o centro de rotação
			flashSprite.x = x * FlxG.scaleMode.scale.x + _flashOffset.x;
			flashSprite.y = y * FlxG.scaleMode.scale.y + _flashOffset.y;
		}
	}
}
