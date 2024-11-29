package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

/**
	*DEBUG MODE
 */
class AnimationDebug extends FlxState
{
	var opp:Character;
	var oppBG:Character;
	// var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var flippedChars:Array<String> = ["pico"];

	public function new(daAnim:String = 'spooky')
	{
		super();
		this.daAnim = daAnim;
	}

	override function create()
	{
		// openfl.Lib.current.stage.frameRate = 144;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

		opp = new Character(0, 0, daAnim);
		opp.screenCenter();
		opp.debugMode = true;

		oppBG = new Character(0, 0, daAnim);
		oppBG.screenCenter();
		oppBG.debugMode = true;
		oppBG.alpha = 0.75;
		oppBG.color = 0xFF000000;

		add(oppBG);
		add(opp);

		opp.flipX = flippedChars.contains(opp.curCharacter);
		oppBG.flipX = flippedChars.contains(oppBG.curCharacter);

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set(0);
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;

		for (anim => offsets in opp.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set(0);
			text.color = FlxColor.BLUE;
			text.cameras = [camHUD];
			dumbTexts.add(text);

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}

	override function update(elapsed:Float)
	{
		textAnim.text = opp.animation.curAnim.name;

		if (FlxG.keys.pressed.E)
			FlxG.camera.zoom += 0.0025;
		if (FlxG.keys.pressed.Q)
			FlxG.camera.zoom -= 0.0025;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -150;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 150;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -150;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 150;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W)
		{
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.S)
		{
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			opp.playAnim(animList[curAnim], true);

			if (animList[curAnim].endsWith("miss"))
				oppBG.playAnim(animList[curAnim].substring(0, animList[curAnim].length - 4), true);
			else
				oppBG.playAnim("idle", true);

			updateTexts();
			genBoyOffsets(false);
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new PlayState());
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
				opp.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				opp.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				opp.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				opp.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			updateTexts();
			genBoyOffsets(false);
			opp.playAnim(animList[curAnim]);
		}
		if (FlxG.keys.justPressed.X)
		{
			opp.flipX = !opp.flipX;
			oppBG.flipX = opp.flipX;
		}

		super.update(elapsed);
	}
}
