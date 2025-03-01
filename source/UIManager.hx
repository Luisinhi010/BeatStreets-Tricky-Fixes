package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.Json;

class UIManager
{
	public static function init()
	{
		ConfigManager.init();
	}

	public static function createButton(x:Float, y:Float, label:String, callback:() -> Void, ?hotkey:String):Dynamic
	{
		var config = ConfigManager.uiConfig;
		var btn = new FlxButton(x, y, label, callback);

		btn.setGraphicSize(config.layout.buttonWidth, config.layout.buttonHeight);
		btn.updateHitbox();
		btn.label.setFormat(null, config.fonts.defaut.size, FlxColor.fromString(config.fonts.defaut.color));
		btn.color = FlxColor.fromString(config.colors.button.normal);

		if (config.effects.buttonHover)
		{
			btn.onOver.callback = () ->
			{
				FlxTween.tween(btn.scale, {
					x: config.animation.buttonScale,
					y: config.animation.buttonScale
				}, config.animation.duration, {
					ease: FlxEase.quartOut
				});
				btn.color = FlxColor.fromString(config.colors.button.hover);
			};

			btn.onOut.callback = () ->
			{
				FlxTween.tween(btn.scale, {x: 1.0, y: 1.0}, config.animation.duration, {
					ease: FlxEase.quartOut
				});
				btn.color = FlxColor.fromString(config.colors.button.normal);
			};
		}

		if (hotkey != null)
		{
			var hotkeyText = new FlxText(btn.x, btn.y + btn.height, btn.width, '[$hotkey]');
			hotkeyText.alignment = CENTER;
			hotkeyText.setFormat(null, config.fonts.tooltip.size, FlxColor.fromString(config.fonts.tooltip.color));
			return {button: btn, tooltip: hotkeyText};
		}

		return btn;
	}

	public static function createPanel(x:Float, y:Float, width:Float, height:Float):FlxSprite
	{
		var config = ConfigManager.uiConfig;
		var panel = new FlxSprite(x, y).makeGraphic(Std.int(width), Std.int(height), FlxColor.fromString(config.colors.panel));
		panel.scrollFactor.set();
		return panel;
	}

	public static function createTooltip(text:String):FlxText
	{
		var config = ConfigManager.uiConfig;
		var tooltip = new FlxText(0, FlxG.height - 40, FlxG.width, text);
		tooltip.setFormat(null, config.fonts.tooltip.size, FlxColor.fromString(config.fonts.tooltip.color), CENTER);

		if (config.effects.tooltipPulse)
		{
			FlxTween.tween(tooltip, {alpha: 0.4}, 1, {
				type: PINGPONG,
				ease: FlxEase.sineInOut
			});
		}

		return tooltip;
	}
}
