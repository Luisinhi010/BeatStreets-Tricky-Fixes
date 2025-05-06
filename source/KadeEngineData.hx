package;

import lime.utils.Assets;
import flixel.FlxG;
import haxe.Json;
import ConfigManager;

class KadeEngineData
{
	public static function initSave()
	{
		ConfigManager.init();

		var gameplay = ConfigManager.defaultConfig.gameplay;
		for (field in Reflect.fields(gameplay))
		{
			var value = Reflect.field(gameplay, field);
			if (Reflect.field(FlxG.save.data, field) == null)
				Reflect.setField(FlxG.save.data, field, value);
		}

		var fpsConfig = ConfigManager.getValue(ConfigManager.defaultConfig, "performance.fpsCap", null);
		if (fpsConfig != null)
		{
			var maxFps = cast fpsConfig.max, Int;
			var minFps = cast fpsConfig.min, Int;
			var currentFpsCap = cast FlxG.save.data.fpsCap, Int;
			if (currentFpsCap > maxFps || currentFpsCap < minFps)
				FlxG.save.data.fpsCap = fpsConfig.defaut;
		}

		// Apply settings
		Conductor.recalculateTimings();
		KeyBinds.keyCheck();
		PlayerSettings.player1.controls.loadKeyBinds();
		Main.setFPSCap(FlxG.save.data.fpsCap);
	}
}
