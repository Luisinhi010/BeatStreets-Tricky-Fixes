package;

import openfl.text.AntiAliasType;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxAxes;
import flixel.tweens.FlxEase;

class Test3DState extends FlxState
{
	private var sprite:CustomSprite;
	private var spritetrail:HazardTrail;
	private var infoText:FlxText;
	private var debugText:FlxText;
	private var camera3D:FlxCamera;

	// Demo controls
	private var currentDemo:Int = 0;
	private var demoNames:Array<String> = ["Basic 3D Movement", "3D Rotation", "3D Tweens", "Perspective and Depth"];

	override public function create():Void
	{
		super.create();
		createBackground();
		setupCameras();
		setupSprite();
		createUI();
	}

	private function setupCameras():Void
	{
		// Criar e configurar a câmera principal
		var mainCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		mainCamera.bgColor = 0xFF222222;

		camera3D = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		camera3D.bgColor = FlxColor.TRANSPARENT;

		FlxG.cameras.reset(mainCamera);
		FlxG.cameras.add(camera3D);

		mainCamera.zoom = 1;
		camera3D.zoom = 1;

		mainCamera.active = true;
		camera3D.active = true;

		// Configurar câmera padrão
		FlxG.camera = mainCamera;
	}

	private function setupSprite():Void
	{
		sprite = new CustomSprite(0, 0);
		sprite.loadGraphic(Paths.image('customnotes/arrowstatic', 'shared'));

		sprite.x = FlxG.width * 0.5 - sprite.width * 0.5;
		sprite.y = FlxG.height * 0.5 - sprite.height * 0.5;
		sprite.antialiasing = true;
		sprite.alpha = 1;

		sprite.enable3D = true;
		sprite.setPosition3D(sprite.x, sprite.y, 0);
		sprite.focalLength = 500;

		sprite.cameras = [camera3D];

		add(sprite);

		spritetrail = new HazardTrail(sprite, Paths.image('customnotes/arrowstatictrail', 'shared'));
		add(spritetrail);

		trace('Sprite dimensions: ${sprite.width}x${sprite.height}');
		trace('Sprite position: ${sprite.x}, ${sprite.y}');
		trace('Sprite 3D position: ${sprite.x3D}, ${sprite.y3D}, ${sprite.z3D}');
		sprite.debugState();
	}

	private function createUI():Void
	{
		try
		{
			// Garantir que estamos usando a câmera principal para a UI
			var uiCamera = FlxG.camera;

			// Top info text with background
			var infoTextBG = new FlxSprite(0, 0);
			infoTextBG.makeGraphic(FlxG.width, 80, 0x88000000);
			infoTextBG.cameras = [uiCamera];
			add(infoTextBG);

			infoText = new FlxText(10, 10, FlxG.width - 20);
			infoText.setFormat(null, 24, FlxColor.WHITE, "center", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			infoText.borderSize = 2;
			infoText.cameras = [uiCamera];
			add(infoText);

			// Bottom debug text with background
			var debugTextBG = new FlxSprite(0, FlxG.height - 80);
			debugTextBG.makeGraphic(FlxG.width, 80, 0x88000000);
			debugTextBG.cameras = [uiCamera];
			add(debugTextBG);

			debugText = new FlxText(10, FlxG.height - 70, FlxG.width - 20);
			debugText.setFormat(null, 16, FlxColor.WHITE, "left", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			debugText.borderSize = 1.5;
			debugText.cameras = [uiCamera];
			add(debugText);

			updateInfoText();
		}
		catch (e:Dynamic)
		{
			trace('Error in createUI: $e');
		}
	}

	private function updateInfoText():Void
	{
		infoText.text = 'Demo: ${demoNames[currentDemo]}\n';

		switch (currentDemo)
		{
			case 0:
				infoText.text += "[Arrows] Move | [Q/E] Depth | [SPACE] Next";
			case 1:
				infoText.text += "[W/A/S/D] Rotate 3D | [SPACE] Next";
			case 2:
				infoText.text += "[1-5] Different Tweens | [SPACE] Next";
			case 3:
				infoText.text += "[Arrows] Move | [C] Toggle Camera | [SPACE] Next";
			case 4:
				infoText.text += "[+/-] Focal Length | [Q/E] Depth | [SPACE] Next";
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.H)
		{
			trace("\n=== DEBUG INFO ===");
			trace('Sprite visible: ${sprite.visible}');
			trace('Sprite alpha: ${sprite.alpha}');
			trace('Sprite position: ${sprite.x}, ${sprite.y}');
			trace('Sprite 3D position: ${sprite.x3D}, ${sprite.y3D}, ${sprite.z3D}');
			trace('Sprite dimensions: ${sprite.width}x${sprite.height}');
			trace('Cameras length: ${sprite.cameras.length}');
			sprite.debugState();
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			currentDemo = (currentDemo + 1) % demoNames.length;
			resetDemo();
			updateInfoText();
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new MainMenuState());

		updateCurrentDemo(elapsed);
		updateDebugText();
	}

	private function resetDemo():Void
	{
		sprite.setPosition3D(FlxG.width / 2, FlxG.height / 2, 0);
		sprite.setRotation3D(0, 0, 0);
		sprite.focalLength = 500;
	}

	private function updateCurrentDemo(elapsed:Float):Void
	{
		switch (currentDemo)
		{
			case 0: // Basic 3D Movement
				updateBasicMovement();
			case 1: // 3D Rotation
				updateRotation();
			case 2: // 3D Tweens
				updateTweens();
			case 3: // Perspective and Depth
				updatePerspective();
		}
	}

	private function updateBasicMovement():Void
	{
		if (FlxG.keys.pressed.LEFT)
			sprite.x3D -= 5;
		if (FlxG.keys.pressed.RIGHT)
			sprite.x3D += 5;
		if (FlxG.keys.pressed.UP)
			sprite.y3D -= 5;
		if (FlxG.keys.pressed.DOWN)
			sprite.y3D += 5;
		if (FlxG.keys.pressed.Q)
			sprite.z3D -= 5;
		if (FlxG.keys.pressed.E)
			sprite.z3D += 5;
	}

	private function updateRotation():Void
	{
		if (FlxG.keys.pressed.W)
			sprite.rotationX -= 4;
		if (FlxG.keys.pressed.S)
			sprite.rotationX += 4;
		if (FlxG.keys.pressed.A)
			sprite.rotationY -= 4;
		if (FlxG.keys.pressed.D)
			sprite.rotationY += 4;

		if (FlxG.keys.justPressed.H)
		{
			trace("\n=== DEBUG INFO ===");
			trace('Sprite visible: ${sprite.visible}');
			trace('Sprite alpha: ${sprite.alpha}');
			trace('Position 3D: (${sprite.x3D}, ${sprite.y3D}, ${sprite.z3D})');
			trace('Rotation: (${sprite.rotationX}, ${sprite.rotationY}, ${sprite.rotationZ})');
		}
	}

	private function updateTweens():Void
	{
		if (FlxG.keys.justPressed.ONE)
			sprite.tweenPosition3D(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height), 0);

		if (FlxG.keys.justPressed.TWO)
			sprite.tweenRotation3D(360, 360, 360, 2.0, FlxEase.quadInOut);

		if (FlxG.keys.justPressed.THREE)
			sprite.tweenPosition3D(FlxG.width / 2, FlxG.height / 2, 500, 1.0, FlxEase.backOut);

		if (FlxG.keys.justPressed.FOUR)
			sprite.tweenRotation3D(0, 360, 0, 1.0, FlxEase.bounceOut);

		if (FlxG.keys.justPressed.FIVE)
		{
			sprite.tweenPosition3D(FlxG.width / 2, FlxG.height / 2, -200);
			sprite.tweenRotation3D(360, 0, 360);
		}
	}

	private function updatePerspective():Void
	{
		if (FlxG.keys.pressed.Q)
			sprite.z3D -= 5;
		if (FlxG.keys.pressed.E)
			sprite.z3D += 5;

		if (FlxG.keys.pressed.PLUS)
			sprite.focalLength += 10;
		if (FlxG.keys.pressed.MINUS)
			sprite.focalLength = Math.max(10, sprite.focalLength - 10);
	}

	private function updateDebugText():Void
	{
		debugText.text = 'Position3D: (${Math.floor(sprite.x3D)}, ${Math.floor(sprite.y3D)}, ${Math.floor(sprite.z3D)})\n'
			+ 'Rotation3D: (${Math.floor(sprite.rotationX)}, ${Math.floor(sprite.rotationY)}, ${Math.floor(sprite.rotationZ)})\n'
			+ 'Focal Length: ${Math.floor(sprite.focalLength)}';
	}

	function createBackground():Void
	{
		var bg = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.y += 40;
		bg.cameras = [FlxG.camera];
		add(bg);

		var mist = new VolumetricCloudSprite(0, 0);
		mist.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		mist.cloudType = MIST;
		mist.setColors(0xFF545FC4, 0xFFCACAFA);
		mist.blend = ADD;
		mist.cameras = [FlxG.camera];
		add(mist);

		function addBackgroundElement(graphic:String, x:Float, y:Float, scale:Float):Void
		{
			var sprite = new FlxSprite(x, y).loadGraphic(Paths.image(graphic, 'clown'));
			sprite.setGraphicSize(Std.int(sprite.width * scale));
			sprite.cameras = [FlxG.camera];
			add(sprite);
		}

		addBackgroundElement('menu/freeplay/hedge', -810, -335, 0.65);
		addBackgroundElement('menu/freeplay/Shadescreen', -205, -100, 0.65);
		addBackgroundElement('menu/freeplay/theBox', -225, -395, 0.65);
	}
}
