package;

import flixel.ui.FlxButton;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText.FlxTextBorderStyle;

class UIEffects
{
	public static function createButtonEffect(button:FlxButton)
	{
		var originalY = button.y;
		button.onOver.callback = () ->
		{
			FlxTween.tween(button, {y: originalY - 3}, 0.1, {ease: FlxEase.quadOut});
		};
		button.onOut.callback = () ->
		{
			FlxTween.tween(button, {y: originalY}, 0.1, {ease: FlxEase.quadIn});
		};
		button.onDown.callback = () ->
		{
			createButtonFlash(button);
		};
	}

	public static function createPulsingText(text:FlxText, minAlpha:Float = 0.4, maxAlpha:Float = 0.8):FlxText
	{
		FlxTween.tween(text, {alpha: minAlpha}, 1, {
			type: PINGPONG,
			ease: FlxEase.sineInOut
		});
		return text;
	}

	public static function createStatusEffect(success:Bool, x:Float, y:Float):Array<FlxSprite>
	{
		var sprites:Array<FlxSprite> = [];
		var color = success ? FlxColor.GREEN : FlxColor.RED;
		var icon = success ? "✓" : "✗";

		// Create particles
		for (i in 0...8)
		{
			var particle = new FlxSprite(x, y).makeGraphic(4, 4, color);
			var angle = (i / 8) * 360;
			var speed = FlxG.random.float(2, 4);
			particle.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
			particle.alpha = 0.6;

			FlxTween.tween(particle, {alpha: 0}, 0.5, {
				onComplete: (_) -> particle.destroy()
			});
			sprites.push(particle);
		}

		// Create status text
		var text = new FlxText(x, y, 0, icon);
		text.setFormat(null, 16, color);
		text.alpha = 0;
		sprites.push(text);

		FlxTween.tween(text, {y: y - 20, alpha: 1}, 0.2, {
			ease: FlxEase.quartOut,
			onComplete: (_) ->
			{
				FlxTween.tween(text, {alpha: 0}, 0.3, {
					startDelay: 0.2,
					onComplete: (_) -> text.destroy()
				});
			}
		});

		return sprites;
	}

	public static function showToast(message:String, color:FlxColor = FlxColor.WHITE, ?duration:Float = 2.0):FlxText
	{
		var toast = new FlxText(0, 0, FlxG.width, message);
		toast.setFormat(null, 20, color, CENTER, FlxTextBorderStyle.OUTLINE);
		toast.borderColor = FlxColor.BLACK;
		toast.screenCenter();
		toast.y = FlxG.height * 0.8;
		toast.alpha = 0;

		FlxTween.tween(toast, {alpha: 1, y: toast.y - 50}, 0.5, {
			ease: FlxEase.circOut,
			onComplete: function(_)
			{
				FlxTween.tween(toast, {alpha: 0, y: toast.y - 50}, 0.5, {
					ease: FlxEase.circIn,
					startDelay: duration,
					onComplete: function(_)
					{
						toast.destroy();
					}
				});
			}
		});

		return toast;
	}

	public static function createTransition(onComplete:() -> Void)
	{
		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0;
		FlxG.state.add(overlay);

		FlxTween.tween(overlay, {alpha: 1}, 0.3, {
			ease: FlxEase.quartInOut,
			onComplete: (_) ->
			{
				onComplete();
				FlxTween.tween(overlay, {alpha: 0}, 0.3, {
					ease: FlxEase.quartInOut,
					onComplete: (_) -> overlay.destroy()
				});
			}
		});
	}

	public static function highlight(sprite:FlxSprite, ?color:FlxColor = FlxColor.WHITE):Void
	{
		var originalAlpha = sprite.alpha;
		FlxTween.tween(sprite, {alpha: 0.3}, 0.1, {
			type: PINGPONG,
			ease: FlxEase.circInOut,
			onComplete: function(_)
			{
				sprite.alpha = originalAlpha;
			}
		});
	}

	public static function shake(sprite:FlxSprite, intensity:Float = 0.01, duration:Float = 0.1)
	{
		sprite.offset.x = FlxG.random.float(-2, 2) * intensity;
		sprite.offset.y = FlxG.random.float(-2, 2) * intensity;

		new FlxTimer().start(duration, (_) ->
		{
			sprite.offset.set();
		});
	}

	private static function createButtonFlash(button:FlxButton)
	{
		var flash = new FlxSprite(button.x, button.y).makeGraphic(Std.int(button.width), Std.int(button.height), FlxColor.WHITE);
		flash.alpha = 0.5;
		FlxG.state.add(flash);

		FlxTween.tween(flash, {alpha: 0}, 0.1, {
			onComplete: (_) -> flash.destroy()
		});
	}
}
