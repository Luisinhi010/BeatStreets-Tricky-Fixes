package effects;

import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CameraEffects
{
	public static function zoomIn(state:PlayState)
	{
		if (state.camGame.zoom < 1.35)
		{
			if (!state.ignoreDefaultZoom)
				state.camGame.zoom += 0.015;
			state.camHUD.zoom += 0.03;
		}
	}

	public static function resetCameras(state:PlayState):Void
	{
		state.camGame.zoom = state.defaultCamZoom;
		state.camHUD.zoom = 1;
		state.camEffect.zoom = 1;
		state.camOther.zoom = 1;

		state.camGame.filters = [new ShaderFilter(state.distortion.shader), new ShaderFilter(state.blur.shader)];

		if (!FlxG.save.data.lowend && state.susWiggleEffect != null)
		{
			state.camEffect.filters = [new ShaderFilter(state.susWiggleEffect.shader)];
		}
	}

	public static function setupCameras(state:PlayState):Void
	{
		FlxG.cameras.reset(state.camGame = new FlxCamera());
		FlxG.cameras.add(state.camHUD = new FlxCamera(), false);
		FlxG.cameras.add(state.camEffect = new FlxCamera(), false);
		FlxG.cameras.add(state.camOther = new FlxCamera(), false);

		for (cam in [state.camHUD, state.camEffect, state.camOther])
			cam.bgColor.alpha = 0;

		FlxG.cameras.setDefaultDrawTarget(state.camGame, true);
	}
}
