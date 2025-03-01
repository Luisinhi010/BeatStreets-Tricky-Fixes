package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import openfl.geom.Rectangle;

/**
 * Câmera especializada com correções para rotação e redimensionamento.
 */
class CustomCamera extends FlxCamera
{
	// Configurações de downscroll
	public var downscroll(default, set):Bool = false;

	private var originalScrollY:Float = 0;

	// Compensação de rotação
	private var _lastAngle:Float = 0;
	private var _rotationBuffer:Float = 1.0;
	private var _originalWidth:Int = 0;
	private var _originalHeight:Int = 0;
	private var _isResizing:Bool = false;

	// Referências ao tamanho da janela
	private var _lastWindowWidth:Int = 0;
	private var _lastWindowHeight:Int = 0;

	// Controle de framerate
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

		// Armazena o tamanho inicial da janela
		_lastWindowWidth = FlxG.width;
		_lastWindowHeight = FlxG.height;

		// Corrige o flashSprite para permitir rotação sem cortar
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
		// Se tem um framerate específico
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
			// Atualização normal
			updateCamera(elapsed);
		}
	}

	/**
	 * Define um framerate específico para esta câmera, diferente do framerate do jogo.
	 * Útil para efeitos como câmera lenta ou simulação de lag.
	 * 
	 * @param fps Framerate desejado. Use 0 para desativar e usar o framerate do jogo.
	 */
	public function setFramerate(fps:Float):Void
	{
		targetFramerate = fps;

		if (fps <= 0)
		{
			// Desativa o controle personalizado de framerate
			frameInterval = 0;
		}
		else
		{
			// Define o intervalo entre frames
			frameInterval = 1 / fps;
		}

		frameTimer = 0;
		lastFrameTime = 0;
	}

	/**
	 * Atualiza a câmera com o elapsed time ajustado.
	 */
	private function updateCamera(elapsed:Float):Void
	{
		// Verifica se houve mudança no tamanho da janela
		if (_lastWindowWidth != FlxG.width || _lastWindowHeight != FlxG.height)
		{
			handleWindowResize();
		}

		// Se o ângulo da câmera mudou, ajusta o tamanho do buffer
		if (_lastAngle != angle)
		{
			applyRotationFix();
			_lastAngle = angle;
		}

		originalScrollY = scroll.y;
		super.update(elapsed);

		// Processa downscroll se necessário
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
		var sinAngle = Math.sin(angleRadians);
		var cosAngle = Math.cos(angleRadians);

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
			{
				updateInternalSpritePositions();
			}
		}

		updateRotatedScrollRect();
	}

	private function updateRotatedScrollRect():Void
	{
		if (_scrollRect != null && _scrollRect.scrollRect != null)
		{
			var rect = _scrollRect.scrollRect;

			var expandedWidth = width * initialZoom * FlxG.scaleMode.scale.x * _rotationBuffer;
			var expandedHeight = height * initialZoom * FlxG.scaleMode.scale.y * _rotationBuffer;

			rect.width = expandedWidth;
			rect.height = expandedHeight;

			rect.x = -((expandedWidth - width * initialZoom * FlxG.scaleMode.scale.x) / 2);
			rect.y = -((expandedHeight - height * initialZoom * FlxG.scaleMode.scale.y) / 2);

			_scrollRect.scrollRect = rect;

			_scrollRect.x = -0.5 * rect.width;
			_scrollRect.y = -0.5 * rect.height;
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
			newHeight = Math.ceil(FlxG.height);
			newWidth = Math.ceil(newHeight * cameraRatio);
		}
		else
		{
			newWidth = Math.ceil(FlxG.width);
			newHeight = Math.ceil(newWidth / cameraRatio);
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
