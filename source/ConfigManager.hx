package;

import lime.utils.Assets;
import haxe.Json;
import flixel.FlxG;
import Config;
import Paths;

class ConfigManager
{
	public static var noteConfig:NoteConfig;
	public static var chartConfig:ChartConfig;
	public static var defaultConfig:DefaultConfig;
	public static var frameConfig:FrameConfig;
	public static var uiConfig:UIConfig;

	private static var initialized:Bool = false;

	public static function init()
	{
		if (initialized)
			return;
		loadConfigs();
		initialized = true;
	}

	private static function loadConfigs()
	{
		loadNoteConfig();
		loadChartConfig();
		loadDefaultConfig();
		loadFrameConfig();
		loadUIConfig();
	}

	public static function loadNoteConfig()
	{
		try
		{
			noteConfig = Paths.loadJson('noteConfig');
			if (noteConfig == null)
				throw 'Config not found';
		}
		catch (e)
		{
			noteConfig = getDefaultNoteConfig();
		}
	}

	public static function loadChartConfig()
	{
		try
		{
			chartConfig = Paths.loadJson('chartConfig');
			if (chartConfig == null)
				throw 'Config not found';
		}
		catch (e)
		{
			chartConfig = getDefaultChartConfig();
		}
	}

	public static function loadDefaultConfig()
	{
		try
		{
			defaultConfig = Paths.loadJson('defaultConfig');
			if (defaultConfig == null)
				throw 'Config not found';
		}
		catch (e)
		{
			defaultConfig = getDefaultGameConfig();
		}
	}

	public static function loadFrameConfig()
	{
		try
		{
			frameConfig = Paths.loadJson('frameConfig');
			if (frameConfig == null)
				throw 'Config not found';
		}
		catch (e)
		{
			frameConfig = getDefaultFrameConfig();
		}
	}

	public static function loadUIConfig()
	{
		try
		{
			uiConfig = Paths.loadJson('uiConfig');
			if (uiConfig == null)
				throw 'Config not found';
		}
		catch (e)
		{
			uiConfig = getDefaultUIConfig();
		}
	}

	public static function getDefaultNoteConfig():NoteConfig
	{
		return {
			offsets: {
				x: 50,
				y: 2000,
				burning: 48,
				halo: 165
			},
			dimensions: {width: 160, scale: 0.7, burningScale: 0.86},
			animations: {
				scrollSuffixes: ["Scroll", "0"],
				holdSuffixes: ["hold", "piece", "end"],
				directions: ["purple", "blue", "green", "red"]
			},
			paths: {
				defaut: {
					normal: "customnotes/Custom_notes",
					hard: "customnotes/Custom_notes_Expurgation"
				},
				burning: {
					normal: "NOTE_fire",
					halo: "fourth/mech/ALL_deathnotes"
				}
			},
			timing: {
				safeZoneOffset: {
					normal: 0.5,
					burning: 0.3,
					halo: 0.2
				}
			},
			colors: {
				notes: [[255, 54, 54], [167, 69, 255], [10, 228, 174], [157, 255, 85]]
			},
			sustain: {
				alpha: 0.6,
				scoreMultiplier: 0.2
			}
		};
	}

	public static function getDefaultChartConfig():ChartConfig
	{
		return {
			gridSize: 40,
			colors: {
				highlight: {
					add: "0xFF0000FF",
					delete: "0xFFFF0000",
					select: "0xFFFFFF00",
					copy: "0xFF00FF00"
				},
				grid: "0xFF333333",
				bg: "0xFF000000",
				ui: {
					bg: "0xFF646464",
					text: "0xFFFFFFFF"
				}
			},
			shortcuts: {
				save: "CONTROL+S",
				undo: "CONTROL+Z",
				redo: "CONTROL+Y",
				copy: "CONTROL+C",
				paste: "CONTROL+V",
				delete: "DELETE",
				selectAll: "CONTROL+A",
				duplicate: "CONTROL+D",
				play: "SPACE",
				reset: "R",
				nudge: "ALT+ARROWS",
				nudgeLeft: "ALT+LEFT",
				nudgeRight: "ALT+RIGHT",
				nudgeUp: "ALT+UP",
				nudgeDown: "ALT+DOWN"
			},
			shortcutLabels: {
				save: "Quick Save",
				undo: "Undo",
				redo: "Redo",
				copy: "Copy",
				paste: "Paste",
				delete: "Delete",
				selectAll: "Select All",
				duplicate: "Duplicate",
				play: "Play/Pause",
				reset: "Reset Section",
				nudge: "Nudge Notes"
			},
			autoSave: {
				enabled: true,
				interval: 60
			},
			defaultSong: {
				bpm: 150,
				speed: 1,
				needsVoices: true
			},
			ui: {
				fontSize: 16,
				padding: 10,
				boxWidth: 300
			}
		};
	}

	public static function getDefaultGameConfig():DefaultConfig
	{
		return {
			gameplay: {
				downscroll: false,
				accuracyDisplay: true,
				offset: 0,
				fps: false,
				fpsCap: 120,
				scrollSpeed: 1,
				frames: 10,
				accuracyMod: 1,
				ghost: true,
				flashing: true,
				botplay: false
			},
			progress: {
				beatenHard: false,
				beatEx: false,
				lowend: false,
				warned: false
			},
			hitPosition: {
				x: -1,
				y: -1,
				changed: false
			},
			performance: {
				fpsCap: {
					min: 60,
					max: 290,
					defaut: 120
				}
			}
		};
	}

	public static function getDefaultFrameConfig():FrameConfig
	{
		var frameMap = new Map();
		frameMap.set("sign", "fourth/mech/Sign_Post_Mechanic");
		frameMap.set("left", "hellclwn/Tricky/Left");
		frameMap.set("right", "hellclwn/Tricky/right");
		frameMap.set("up", "hellclwn/Tricky/Up");
		frameMap.set("down", "hellclwn/Tricky/Down");
		frameMap.set("char_TrickyH", "hellclwn/Tricky/Idle");
		frameMap.set("grem", "fourth/mech/HP GREMLIN");
		frameMap.set("cln", "fourth/Clone");

		return {
			frames: frameMap,
			settings: {
				persist: true,
				destroyOnNoUse: false
			}
		};
	}

	public static function getDefaultUIConfig():UIConfig
	{
		return {
			colors: {
				background: "0xFF2C2C2C",
				panel: "0xFF2A2A2A",
				sidePanel: "0xFF1A1A1A",
				text: "0xFFFFFFFF",
				highlight: "0xFF00FF00",
				error: "0xFFFF0000",
				success: "0xFF00FF00",
				warning: "0xFFFFFF00",
				button: {
					normal: "0xFF4A4A4A",
					hover: "0xFF666666",
					pressed: "0xFF333333"
				}
			},
			fonts: {
				defaut: {
					size: 16,
					color: "0xFFFFFFFF"
				},
				title: {
					size: 24,
					color: "0xFFFFFFFF"
				},
				tooltip: {
					size: 12,
					color: "0xFFCCCCCC"
				}
			},
			layout: {
				padding: 10,
				spacing: 5,
				buttonWidth: 200,
				buttonHeight: 30,
				panelWidth: 300,
				sidebarWidth: 250
			},
			animation: {
				duration: 0.3,
				ease: "quartOut",
				buttonScale: 1.1,
				fadeSpeed: 0.2
			},
			effects: {
				tooltipPulse: true,
				buttonHover: true,
				transitions: true,
				shake: {
					intensity: 0.003,
					duration: 0.2
				}
			}
		};
	}

	public static function getValue<T>(config:Dynamic, path:String, defaultValue:T):T
	{
		var parts = path.split(".");
		var current = config;

		for (part in parts)
		{
			if (current == null || !Reflect.hasField(current, part))
				return defaultValue;
			current = Reflect.field(current, part);
		}

		return current != null ? current : defaultValue;
	}

	public static function saveConfig(config:Dynamic, filename:String)
	{
		try
		{
			var data = Json.stringify(config, null, "  ");
			#if sys
			sys.io.File.saveContent('assets/preload/data/$filename.json', data);
			#else
			FlxG.save.data['config_$filename'] = data;
			FlxG.save.flush();
			#end
		}
		catch (e)
		{
			trace('Failed to save config: ${e.message}');
		}
	}
}
