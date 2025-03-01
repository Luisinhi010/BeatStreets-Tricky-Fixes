package effects;

import Shaders;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.filters.ShaderFilter;

using StringTools;

class VisualEffects
{
	public static function madnessEffect(state:PlayState)
	{
		FlxTween.tween(state.behindCharacters, {alpha: 1}, Conductor.beatTime);
		FlxTween.tween(state, {burningnotealpha: 0.8}, Conductor.beatTime * 2);
		FlxTween.tween(state.blur, {multiplier: 0.4}, 1);
		FlxTween.tween(state.distortion, {multiplier: 0.8}, 1);
		FlxTween.tween(state.iconP1, {alpha: 0}, Conductor.beatTime * 4);
		FlxTween.tween(state.iconP2, {alpha: 0}, Conductor.beatTime * 4);
		FlxTween.tween(state.scoreTxt, {alpha: 0}, Conductor.beatTime * 4);
		FlxTween.tween(state.judgementCounter, {alpha: 0}, Conductor.beatTime * 4);

		state.defaultCamZoom = 0.85;
		state.hardermode = true;
		FlxTween.tween(state.colorSwap, {hue: state.ogOffset}, Conductor.beatTime);
	}

	public static function createSpookyText(state:PlayState, text:String, x:Float = null, y:Float = null)
	{
		state.spookySteps = state.curStep;
		state.spookyRendered = true;
		state.tstatic.alpha = 0.5;
		FlxG.sound.play(Paths.sound('staticSound', 'clown'));

		var finalX = x ?? FlxG.random.float(state.opp.x + 40, state.opp.x + 120);
		var finalY = y ?? FlxG.random.float(state.opp.y + 200, state.opp.y + 300);

		var spookyText = new FlxText(finalX, finalY);
		var textColor = PlayState.SONG.stage.endsWith('-upside') ? FlxColor.MAGENTA : FlxColor.BLUE;
		spookyText.setFormat("Impact", 128, textColor);

		if (PlayState.SONG.stage == 'nevada-spook')
		{
			spookyText.size = 200;
			spookyText.x += 250;
		}

		spookyText.bold = true;
		spookyText.text = text;
		spookyText.pixelPerfectPosition = spookyText.pixelPerfectRender = true;

		state.add(spookyText);
		state.spookyText = spookyText;
	}

	public static function doCloneEffect(state:PlayState, side:Int)
	{
		var clone:FlxSprite = (side == 0) ? state.cloneOne : state.cloneTwo;
		if (clone.alpha == 1 || clone == null)
			return;

		clone.x = state.opp.x + (side == 0 ? -20 : 390);
		clone.y = state.opp.y + 140;
		clone.alpha = 1;

		clone.animation.play('clone');
		clone.animation.finishCallback = function(_:String)
		{
			clone.alpha = 0;
		};
	}

	public static function updateSpookyText(state:PlayState, elapsed:Float):Void
	{
		if (state.spookyText != null)
		{
			state.spookyText.angle = FlxG.random.int(-5, 5);
			if (state.tstatic.alpha >= 0.1)
			{
				state.tstatic.alpha = FlxG.random.float(0.1, 0.5);
			}
		}
	}

	public static function setupEffects(state:PlayState):Void
	{
		state.gammaCorrection = new GammaCorrectionEffect();
		state.mosaic = new MosaicEffect();
		state.distortion = new TextureDistortionEffect();
		state.blur = new VignetteBlurEffect();

		state.camGame.filters = [new ShaderFilter(state.distortion.shader), new ShaderFilter(state.blur.shader)];
	}
}
