package;

import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import sys.FileSystem;
import flixel.tweens.FlxEase;
import flixel.addons.display.FlxBackdrop;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import Character;

using StringTools;

class CharacterTestState extends MusicBeatState
{
	var char:Character;
	var curAnim:Int = 0;
	var infoText:FlxText;

	var currentCharIndex:Int = 0;
	var characters:Array<String>;
	var animationPreview:FlxSprite;
	var statusText:FlxText;
	var tooltipText:FlxText;

	private var dragCamera:Bool = false;
	private var lastMousePos:FlxPoint;
	private var spriteViewMode:Bool = false;
	private var spriteSheet:FlxSprite;

	private var sidePanel:FlxSprite;
	private var animList:FlxText;
	private var categorizedAnims:Map<String, Array<String>>;
	var following:Bool = true;

	var mainPanel:FlxSprite;
	var previewActive:Bool = false;
	var cameraFollowing:Bool = false;
	private var cameraLocked:Bool = false;
	private var defaultZoom:Float = 1.0;

	private var previewWindow:FlxSprite;
	private var previewBG:FlxSprite;
	private var previewText:FlxText;
	private var currentPreviewAnim:String;

	private var bgGroup:FlxGroup;
	private var characterGroup:FlxGroup;
	private var uiGroup:FlxGroup;

	override public function create()
	{
		super.create();

		// Configurar câmera UI
		var uiCamera = new FlxCamera();
		uiCamera.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(uiCamera, false);

		// Criar grupos com ordem específica
		bgGroup = new FlxGroup();
		characterGroup = new FlxGroup();
		uiGroup = new FlxGroup();

		// Adicionar grupos na ordem correta
		add(bgGroup);
		add(characterGroup);
		add(uiGroup);

		// Configurar câmeras para os grupos
		uiGroup.cameras = [uiCamera];

		// Background e painéis no grupo de background
		var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF2C2C2C);
		bgGroup.add(bg);

		mainPanel = new FlxSprite(260, 40).makeGraphic(FlxG.width - 270, FlxG.height - 50, 0xFF2A2A2A);
		mainPanel.scrollFactor.set();
		bgGroup.add(mainPanel);

		sidePanel = new FlxSprite(0, 0).makeGraphic(250, FlxG.height, 0xFF1A1A1A);
		sidePanel.scrollFactor.set();
		bgGroup.add(sidePanel);

		// Inicializar variáveis importantes
		lastMousePos = FlxPoint.get();
		characters = loadAvailableCharacters();

		if (characters != null && characters.length > 0)
		{
			char = new Character(0, 0, characters[currentCharIndex]);
			if (char != null)
			{
				char.setPosition(mainPanel.x + mainPanel.width / 2 - char.width / 2, mainPanel.y + mainPanel.height / 2 - char.height / 2);
				char.scrollFactor.set();
				characterGroup.add(char);
			}
		}

		// Interface e controles no grupo UI
		createInfoInterface();
		createControls();
		createTooltip();
		updateCharacterInfo();

		// Adicionar fadeSprite ao grupo UI
		var fadeSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		uiGroup.add(fadeSprite);

		FlxTween.tween(fadeSprite, {alpha: 0}, 0.3, {
			onComplete: (_) -> fadeSprite.destroy()
		});
	}

	private function loadAvailableCharacters():Array<String>
	{
		var chars:Array<String> = [];
		var charactersPath = "assets/preload/data/characters/";

		#if sys
		if (FileSystem.exists(charactersPath))
		{
			for (file in FileSystem.readDirectory(charactersPath))
			{
				if (file.endsWith(".json"))
				{
					var charName = file.substring(0, file.length - 5);
					chars.push(charName);
				}
			}
		}
		#end

		// Adicionar personagens de mods
		if (ModManager.activeMods != null)
		{
			for (mod in ModManager.activeMods)
			{
				var modCharPath = mod.path + "characters/";
				if (FileSystem.exists(modCharPath))
				{
					for (file in FileSystem.readDirectory(modCharPath))
					{
						if (file.endsWith(".json"))
						{
							var charName = file.substring(0, file.length - 5);
							if (!chars.contains(charName))
							{
								chars.push(charName);
							}
						}
					}
				}
			}
		}

		// Ordenar alfabeticamente
		chars.sort((a, b) -> a.toLowerCase() > b.toLowerCase() ? 1 : -1);

		// Fallback para lista padrão se nenhum personagem for encontrado
		if (chars.length == 0)
		{
			chars = CoolUtil.coolTextFile(Paths.txt('characterList'));
		}

		return chars;
	}

	function createInfoInterface()
	{
		// Informações do personagem em categorias
		infoText = new FlxText(10, 10, 230);
		infoText.setFormat(null, 16, FlxColor.WHITE, LEFT);
		infoText.scrollFactor.set();
		infoText.cameras = [FlxG.cameras.list[0]]; // Garantir que use a câmera principal
		uiGroup.add(infoText);

		// Lista de animações categorizada
		animList = new FlxText(10, 120, 230);
		animList.setFormat(null, 14, FlxColor.WHITE, LEFT);
		animList.scrollFactor.set();
		animList.cameras = [FlxG.cameras.list[0]];
		uiGroup.add(animList);

		// Status na parte inferior
		statusText = new FlxText(260, FlxG.height - 60, FlxG.width - 270);
		statusText.setFormat(null, 14, FlxColor.LIME, RIGHT);
		statusText.scrollFactor.set();
		statusText.cameras = [FlxG.cameras.list[0]];
		uiGroup.add(statusText);

		// Ajustar posições para evitar sobreposição
		infoText.x = 10;
		infoText.y = 10;

		animList.x = 10;
		animList.y = infoText.y + infoText.height + 20;

		statusText.x = mainPanel.x + 10;
		statusText.y = FlxG.height - 30;
	}

	function updateCharacterInfo()
	{
		if (char == null || char.animation == null)
			return;

		// Categorizar animações
		categorizedAnims = new Map();
		var allAnims = char.animation.getNameList();

		for (anim in allAnims)
		{
			var category = getAnimCategory(anim);
			if (!categorizedAnims.exists(category))
				categorizedAnims.set(category, []);
			categorizedAnims.get(category).push(anim);
		}

		// Informações básicas
		infoText.text = '== CHARACTER INFO ==\n'
			+ 'Name: ${char.curCharacter}\n'
			+ 'Position: (${Math.floor(char.x)}, ${Math.floor(char.y)})\n'
			+ 'Scale: ${char.scale.x}x${char.scale.y}\n'
			+ 'Total Animations: ${allAnims.length}';

		// Lista de animações por categoria
		var animText = '\n== ANIMATIONS ==\n';
		for (category => anims in categorizedAnims)
		{
			animText += '\n$category:\n';
			for (anim in anims)
			{
				animText += '  • $anim\n';
			}
		}
		animList.y = infoText.y + infoText.height + 20;
		animList.text = animText;
	}

	function getAnimCategory(animName:String):String
	{
		return if (animName.startsWith("sing")) "Singing" else if (animName.contains("idle")) "Idle" else if (animName.contains("miss")) "Miss" else
			if (animName.contains("hey")
			|| animName.contains("dance")) "Special" else "Other";
	}

	function createControls()
	{
		var controls = [
			{
				group: "Character",
				buttons: [
					{label: "Previous", callback: prevCharacter, key: "LEFT"},
					{label: "Next", callback: nextCharacter, key: "RIGHT"},
					{label: "Reset", callback: resetCharacter, key: "R"},
					{label: "View Sprite", callback: toggleSpriteView, key: "V"}
				]
			},
			{
				group: "Camera",
				buttons: [
					{label: "Reset", callback: resetCamera, key: "SPACE"},
					{label: "Follow", callback: toggleFollow, key: "F"}
				]
			},
			{
				group: "Animation",
				buttons: [
					{label: "Play", callback: playCurrentAnim, key: "SPACE"},
					{label: "Stop", callback: stopAnim, key: "S"}
				]
			}
		];

		var y = FlxG.height - 240;
		for (group in controls)
		{
			// Adicionar título do grupo
			var groupText = new FlxText(260, y, FlxG.width - 270, group.group);
			groupText.setFormat(null, 12, FlxColor.GRAY, LEFT);
			groupText.scrollFactor.set();
			groupText.cameras = [FlxG.cameras.list[0]];
			uiGroup.add(groupText);
			y += 20;

			// Adicionar botões
			var x:Float = 260;
			for (btn in group.buttons)
			{
				var button = createStylizedButton(x, y, btn.label, btn.callback, btn.key);
				x += button.width + 10;
			}
			y += 40;
		}
	}

	function createStylizedButton(x:Float, y:Float, label:String, callback:() -> Void, hotkey:String):FlxButton
	{
		var btn = new FlxButton(x, y, label, callback);
		btn.label.setFormat(null, 12, FlxColor.WHITE, CENTER);
		btn.label.y -= 2;
		btn.scrollFactor.set();
		btn.cameras = [FlxG.cameras.list[0]];

		var hotkeyText = new FlxText(btn.x, btn.y + btn.height, btn.width, '[$hotkey]');
		hotkeyText.alignment = CENTER;
		hotkeyText.color = FlxColor.GRAY;
		hotkeyText.size = 10;
		hotkeyText.scrollFactor.set();
		hotkeyText.cameras = [FlxG.cameras.list[0]];
		uiGroup.add(hotkeyText);

		btn.onOver.callback = () ->
		{
			FlxTween.tween(btn.scale, {x: 1.1, y: 1.1}, 0.1, {ease: FlxEase.quadOut});
			btn.color = FlxColor.fromRGB(200, 200, 200);
		};
		btn.onOut.callback = () ->
		{
			FlxTween.tween(btn.scale, {x: 1.0, y: 1.0}, 0.1, {ease: FlxEase.quadOut});
			btn.color = FlxColor.WHITE;
		};

		btn.scrollFactor.set();
		uiGroup.add(btn);
		return btn;
	}

	function createTooltip()
	{
		tooltipText = new FlxText(0, FlxG.height - 40, FlxG.width);
		tooltipText.setFormat(null, 12, FlxColor.WHITE, CENTER);
		tooltipText.text = "LEFT/RIGHT: Change Character | SPACE: Play Animation | R: Reset | ESC: Back";
		tooltipText.alpha = 0.7;
		tooltipText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1);
		tooltipText.scrollFactor.set();
		tooltipText.cameras = [FlxG.cameras.list[0]];
		uiGroup.add(tooltipText);

		// Efeito de pulsar
		FlxTween.tween(tooltipText, {alpha: 0.4}, 1, {
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});
	}

	function playCurrentAnim()
	{
		if (char.animation.curAnim == null)
			return;

		var animName = char.animation.curAnim.name;
		char.playAnim(animName, true);

		// Efeitos visuais
		UIEffects.createStatusEffect(true, char.x + char.width / 2, char.y);
		UIEffects.highlight(char);

		var frameData = char.animation.getByName(animName);
		var animInfo = new FlxText(10, FlxG.height - 120, FlxG.width - 20);
		animInfo.text = 'Animation: $animName\n'
			+ 'Frames: ${frameData.frames.length}\n'
			+ 'FPS: ${frameData.frameRate}\n'
			+ 'Looped: ${frameData.looped}';
		animInfo.scrollFactor.set();
		animInfo.cameras = [FlxG.cameras.list[0]];
		uiGroup.add(animInfo);

		FlxTween.tween(animInfo, {alpha: 0}, 2, {
			startDelay: 1,
			onComplete: (_) -> animInfo.destroy()
		});
	}

	function showStatus(text:String, ?color:FlxColor)
	{
		if (color == null)
			color = FlxColor.LIME;

		statusText.color = color;
		statusText.text = text;
		statusText.alpha = 1;

		if (statusText.scale.x != 1)
		{
			statusText.scale.set(1, 1);
			FlxTween.tween(statusText, {alpha: 0}, 1, {startDelay: 1});
		}

		// Efeito de escala
		statusText.scale.set(1.2, 1.2);
		FlxTween.tween(statusText.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.backOut});
	}

	function nextCharacter()
	{
		currentCharIndex++;
		if (currentCharIndex >= characters.length)
			currentCharIndex = 0;
		changeCharacter();
	}

	function prevCharacter()
	{
		currentCharIndex--;
		if (currentCharIndex < 0)
			currentCharIndex = characters.length - 1;
		changeCharacter();
	}

	function changeCharacter()
	{
		if (characters == null || characters.length == 0)
			return;

		UIEffects.createTransition(() ->
		{
			if (char != null)
			{
				characterGroup.remove(char); // Usar remove do grupo
				var oldChar = char;
				FlxTween.tween(oldChar, {alpha: 0, y: oldChar.y + 50}, 0.2, {
					ease: FlxEase.backIn,
					onComplete: (_) -> oldChar.destroy()
				});
			}

			char = new Character(0, 0, characters[currentCharIndex]);
			if (char != null)
			{
				char.setPosition(mainPanel.x + mainPanel.width / 2 - char.width / 2, mainPanel.y + mainPanel.height / 2 - char.height / 2);
				char.alpha = 0;
				char.y -= 50;
				characterGroup.add(char); // Adicionar ao grupo de personagens

				FlxTween.tween(char, {alpha: 1, y: char.y + 50}, 0.3, {
					ease: FlxEase.backOut,
					onComplete: (_) ->
					{
						char.alpha = 1; // Garantir que a visibilidade está 100%
					}
				});

				updateCharacterInfo();
				UIEffects.showToast('Changed to: ${characters[currentCharIndex]}', FlxColor.LIME);
			}
		});
	}

	function resetCharacter()
	{
		UIEffects.createTransition(() ->
		{
			char.dance();
			char.screenCenter(X);
			UIEffects.showToast("Character Reset!", FlxColor.YELLOW);
		});
	}

	function previewAnimation(animName:String)
	{
		if (!previewActive || animName == currentPreviewAnim)
			return;

		// Limpar preview anterior
		cleanupPreview();

		// Criar background do preview
		previewBG = new FlxSprite(sidePanel.x + sidePanel.width + 10, FlxG.height - 180).makeGraphic(200, 160, 0xFF232323);
		previewBG.alpha = 0.8;
		previewBG.scrollFactor.set();
		uiGroup.add(previewBG);

		// Criar janela de preview
		previewWindow = new FlxSprite(previewBG.x + 10, previewBG.y + 30);
		previewWindow.frames = char.frames;
		previewWindow.animation.copyFrom(char.animation);
		previewWindow.animation.play(animName);
		previewWindow.setGraphicSize(100, 100);
		previewWindow.updateHitbox();
		previewWindow.screenCenter(X);
		previewWindow.x = previewBG.x + (previewBG.width - previewWindow.width) / 2;
		previewWindow.scrollFactor.set();
		uiGroup.add(previewWindow);

		// Informações da animação
		var frameData = char.animation.getByName(animName);
		previewText = new FlxText(previewBG.x + 5, previewBG.y + 5, previewBG.width - 10);
		previewText.alignment = CENTER;
		previewText.text = '== $animName ==\n'
			+ 'Frames: ${frameData.frames.length}\n'
			+ 'FPS: ${frameData.frameRate}\n'
			+ 'Looped: ${frameData.looped}';
		previewText.scrollFactor.set();
		uiGroup.add(previewText);

		// Efeitos visuais
		previewBG.alpha = 0;
		previewWindow.alpha = 0;
		previewText.alpha = 0;

		// Animação de entrada
		FlxTween.tween(previewBG, {alpha: 0.8}, 0.3, {ease: FlxEase.quartOut});
		FlxTween.tween(previewWindow, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});
		FlxTween.tween(previewText, {alpha: 1}, 0.3, {ease: FlxEase.quartOut});

		currentPreviewAnim = animName;
	}

	function cleanupPreview()
	{
		if (previewWindow != null)
		{
			previewWindow.destroy();
			previewWindow = null;
		}
		if (previewBG != null)
		{
			previewBG.destroy();
			previewBG = null;
		}
		if (previewText != null)
		{
			previewText.destroy();
			previewText = null;
		}
		currentPreviewAnim = null;
	}

	function toggleSpriteView()
	{
		spriteViewMode = !spriteViewMode;

		if (spriteViewMode)
		{
			if (spriteSheet != null)
				spriteSheet.destroy();

			// Criar visualização do spritesheet
			spriteSheet = new FlxSprite(0, 0);
			spriteSheet.frames = char.frames;
			spriteSheet.scrollFactor.set();

			// Ajustar escala para caber na tela
			var scale = Math.min((FlxG.width * 0.8) / spriteSheet.width, (FlxG.height * 0.8) / spriteSheet.height);
			spriteSheet.scale.set(scale, scale);
			spriteSheet.updateHitbox();
			spriteSheet.screenCenter();

			add(spriteSheet);
			char.visible = false;
		}
		else
		{
			if (spriteSheet != null)
			{
				spriteSheet.destroy();
				spriteSheet = null;
			}
			char.visible = true;
		}
	}

	function resetCamera()
	{
		FlxTween.tween(FlxG.camera, {
			zoom: defaultZoom,
			scroll: {x: 0, y: 0}
		}, 0.5, {ease: FlxEase.quartOut});

		// Resetar estado da câmera
		cameraFollowing = false;
		cameraLocked = false;
		FlxG.camera.follow(null);

		showStatus("Camera Reset");
	}

	function toggleFollow()
	{
		cameraFollowing = !cameraFollowing;
		if (cameraFollowing)
		{
			FlxG.camera.follow(char, LOCKON, 0.05);
			cameraLocked = true;
			showStatus("Camera Following");
		}
		else
		{
			FlxG.camera.follow(null);
			cameraLocked = false;
			showStatus("Free Camera");
		}
	}

	function stopAnim()
	{
		char.animation.pause();
		showStatus("Animation Paused");
	}

	function showEffect(success:Bool, x:Float, y:Float)
	{
		var effects = UIEffects.createStatusEffect(success, x, y);
		for (effect in effects)
			add(effect);
	}

	function showMessage(message:String, color:FlxColor = FlxColor.WHITE)
	{
		var toast = UIEffects.showToast(message, color);
		add(toast);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (char == null)
			return;

		// Controles de câmera simplificados
		if (FlxG.mouse.pressedMiddle)
		{
			if (!dragCamera && !cameraLocked)
			{
				dragCamera = true;
				lastMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
			}

			if (dragCamera)
			{
				var deltaX = (lastMousePos.x - FlxG.mouse.x) * (1 / FlxG.camera.zoom);
				var deltaY = (lastMousePos.y - FlxG.mouse.y) * (1 / FlxG.camera.zoom);

				FlxG.camera.scroll.x += deltaX;
				FlxG.camera.scroll.y += deltaY;

				lastMousePos.set(FlxG.mouse.x, FlxG.mouse.y);
			}
		}
		else
		{
			dragCamera = false;
		}

		// Movimento de câmera com WASD quando não estiver seguindo
		if (!cameraLocked)
		{
			var speed = FlxG.keys.pressed.SHIFT ? 10 : 5;

			if (FlxG.keys.pressed.W)
				FlxG.camera.scroll.y -= speed;
			if (FlxG.keys.pressed.S)
				FlxG.camera.scroll.y += speed;
			if (FlxG.keys.pressed.A)
				FlxG.camera.scroll.x -= speed;
			if (FlxG.keys.pressed.D)
				FlxG.camera.scroll.x += speed;
		}

		// Zoom com mouse wheel
		if (FlxG.mouse.wheel != 0)
		{
			var zoom = FlxG.camera.zoom;
			zoom += FlxG.mouse.wheel * (FlxG.keys.pressed.SHIFT ? 0.1 : 0.05);
			zoom = Math.max(0.1, Math.min(3.0, zoom));
			FlxTween.tween(FlxG.camera, {zoom: zoom}, 0.1, {ease: FlxEase.quadOut});
		}

		// Corrigir controle de espaço para não fechar o jogo
		if (FlxG.keys.justPressed.SPACE && !FlxG.keys.pressed.ALT)
		{
			playCurrentAnim();
			return; // Prevenir que continue processando outros inputs
		}

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new ModTestState());

		if (FlxG.keys.justPressed.R)
			resetCharacter();

		if (FlxG.keys.justPressed.LEFT)
			prevCharacter();

		if (FlxG.keys.justPressed.RIGHT)
			nextCharacter();

		if (FlxG.keys.justPressed.F)
			toggleFollow();

		// Movimento do personagem
		if (FlxG.keys.pressed.SHIFT)
		{
			var charSpeed = 2;
			if (FlxG.keys.pressed.UP)
				char.y -= charSpeed;
			if (FlxG.keys.pressed.DOWN)
				char.y += charSpeed;
			if (FlxG.keys.pressed.LEFT)
				char.x -= charSpeed;
			if (FlxG.keys.pressed.RIGHT)
				char.x += charSpeed;
			updateCharacterInfo();
		}

		// Preview de animação
		if (FlxG.keys.justPressed.P)
		{
			previewActive = !previewActive;
			if (!previewActive && animationPreview != null)
			{
				animationPreview.destroy();
				animationPreview = null;
			}
			showStatus(previewActive ? "Animation Preview ON" : "Animation Preview OFF");
		}

		if (previewActive && FlxG.mouse.justMoved)
		{
			var mouseOverList = FlxG.mouse.overlaps(animList);
			if (!mouseOverList)
			{
				cleanupPreview();
			}
			else
			{
				var relativeY = (FlxG.mouse.y - animList.y);
				var lineHeight = 20;
				var index = Math.floor(relativeY / lineHeight);

				if (index >= 0 && index < char.animation.getNameList().length)
				{
					var animName = char.animation.getNameList()[index];
					previewAnimation(animName);
				}
			}
		}

		updateCharacterInfo();
	}

	override function destroy()
	{
		if (lastMousePos != null)
		{
			lastMousePos.put();
			lastMousePos = null;
		}
		super.destroy();
	}
}
