package;

import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.text.FlxInputText;
import flixel.tweens.FlxTween;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.net.FileReference;
import haxe.Json;
import Paths;

class ConfigTester extends FlxState
{
	var currentConfig:String = "noteConfig";
    var configData:Dynamic;
    var previewSprite:Dynamic;
    var infoText:FlxText;
    var jsonText:FlxInputText;
    var colors:Array<FlxSprite> = [];
    var highlights:Array<FlxSprite> = [];
    var _file:FileReference;

    override function create() {
        bgColor = 0xFF2C2C2C;

        infoText = new FlxText(10, 10, FlxG.width - 20).setFormat(null, 16, FlxColor.BLACK);
        infoText.scrollFactor.set();
        add(infoText);

        jsonText = new FlxInputText(FlxG.width / 2 , 10, FlxG.width/2 - 10, 200);
        jsonText.setFormat(null, 12, FlxColor.BLACK);
        jsonText.multiline = true;
        add(jsonText);

        previewSprite = new FlxSprite(0, 0).makeGraphic(300, 300, FlxColor.BLACK);
        previewSprite.setPosition(FlxG.width / 4 - previewSprite.width / 2, FlxG.height / 2 - previewSprite.height / 2);
        previewSprite.scrollFactor.set();
        add(previewSprite);

        var configButtons:Array<String> = ["Note Config", "Chart Config", "Default Config"];
        var configNames:Array<String> = ["noteConfig", "chartConfig", "defaultConfig"];
        for (i in 0...configButtons.length) {
            addConfigButton(configButtons[i], configNames[i], 10 + i * 30);
        }

        var buttonData = [
            { label: "Save Changes", callback: saveConfig },
            { label: "Reload", callback: loadCurrentConfig },
            { label: "Test Preview", callback: testConfig },
            { label: "Reset", callback: resetConfig },
            { label: "Export", callback: exportConfig }
        ];
        var buttonY = jsonText.y + jsonText.height + 10;
        for (data in buttonData) {
            var button = new FlxButton(jsonText.x - 10, buttonY, data.label, data.callback);
            button.scrollFactor.set();
            add(button);
            buttonY += button.height + 10;
        }

        loadCurrentConfig();
    }

	function addConfigButton(label:String, configName:String, y:Float):Void {
        var btn = new FlxButton(FlxG.width - 110, y, label, () -> {
            currentConfig = configName;
            loadCurrentConfig();
        });
        btn.scrollFactor.set();
        add(btn);
    }

    function loadCurrentConfig():Void {
        try {
            var rawData = Paths.loadJson(currentConfig);
            if (rawData == null) {
                showError('Config file not found: $currentConfig');
                configData = getDefaultConfig();
                return;
            }

            configData = rawData;
            updatePreview();
            createEditor();
        } catch (e) {
            showError('Failed to load $currentConfig: $e');
            configData = getDefaultConfig();
        }
    }

    private function getDefaultConfig():Dynamic {
        return switch(currentConfig) {
            case "noteConfig": {
                dimensions: { scale: 1.0, width: 160 },
                colors: { notes: [[194, 75, 153], [0, 255, 0]] }
            };
            case "chartConfig": {
                gridSize: 40,
                ui: { boxWidth: 300 }
            };
            case "defaultConfig": {
                performance: { fpsCap: { defaut: 120, min: 60, max: 240 } },
                gameplay: { downscroll: false }
            };
            default: {};
        }
    }

	function updatePreview()
	{
		infoText.text = 'Testing ${currentConfig}\n\n' + getConfigInfo();
		jsonText.text = Json.stringify(configData, null, "  ");

		switch (currentConfig)
		{
			case "noteConfig":
				previewNote();
			case "chartConfig":
				previewChart();
			case "defaultConfig":
				previewGameSettings();
		}
	}

	function getConfigInfo():String
	{
		var info = "";
		switch (currentConfig)
		{
			case "noteConfig":
				info = 'Note Scale: ${configData.dimensions.scale}\n';
				info += 'Note Width: ${configData.dimensions.width}\n';
				info += 'Colors: ${configData.colors.notes.length} styles\n';
				info += 'Paths: ${Reflect.fields(configData.paths).length} types';
			case "chartConfig":
				info = 'Grid Size: ${configData.gridSize}\n';
				info += 'Shortcuts: ${Reflect.fields(configData.shortcuts).length} binds\n';
				info += 'UI Size: ${configData.ui.boxWidth}px width';
			case "defaultConfig":
				info = 'FPS Cap: ${configData.performance.fpsCap.defaut}\n';
				info += 'Gameplay Options: ${Reflect.fields(configData.gameplay).length}\n';
				info += 'Progress Stats: ${Reflect.fields(configData.progress).length}';
		}
		return info;
	}

	function previewNote():Void {
        previewSprite.destroy();

        previewSprite = new Note(0, 0, 0, false);
        previewSprite.setGraphicSize(Std.int(configData.dimensions.width * configData.dimensions.scale));
        previewSprite.updateHitbox();
        previewSprite.setPosition(FlxG.width / 4 - previewSprite.width / 2, FlxG.height / 2 - previewSprite.height / 2);
        previewSprite.scrollFactor.set();
        add(previewSprite);

        for (i in 0...configData.colors.notes.length) {
            var color = configData.colors.notes[i];
            var overlay:FlxSprite = (i < colors.length) ? colors[i] : colors[i] = new FlxSprite();
            overlay.makeGraphic(30, 30, FlxColor.fromRGB(color[0], color[1], color[2]));
            overlay.setPosition(previewSprite.x + i * 40, previewSprite.y + 100);
            add(overlay);
        }
    }

	function previewChart()
	{
		if (previewSprite != null)
		{
			previewSprite.destroy();
		}

		// Create mini chart preview
		var gridSize = configData.gridSize;
		previewSprite = FlxGridOverlay.create(gridSize, gridSize, gridSize * 4, gridSize * 4);
		previewSprite.y = FlxG.height / 2 - previewSprite.height / 2;
		previewSprite.x = FlxG.width / 4 - previewSprite.width / 2;
        previewSprite.scrollFactor.set();
		add(previewSprite);

		// Add highlight examples
		var highlightNames = ['add', 'delete', 'select', 'copy'];
		for (i in 0...highlightNames.length)
		{
			if (i < highlights.length && highlights[i] != null)
				highlights[i].destroy();
			var color = Reflect.field(configData.colors.highlight, highlightNames[i]);
			var highlight = new FlxSprite(previewSprite.x + (i * gridSize), previewSprite.y);
			highlight.makeGraphic(gridSize, gridSize, FlxColor.fromString(color));
			highlight.alpha = 0.5;
			if (i < highlights.length)
			{
				highlights[i] = highlight;
			}
			else
			{
				highlights.push(highlight);
			}
			add(highlight);
		}
	}

	function previewGameSettings()
	{
		if (previewSprite != null)
		{
			previewSprite.destroy();
		}

		// Create settings preview
		var settingsText = "";
		for (field in Reflect.fields(configData.gameplay))
		{
			var value = Reflect.field(configData.gameplay, field);
			settingsText += '${field}: ${value}\n';
		}

		previewSprite = new FlxText(0, 0, 280, settingsText);
		previewSprite.setFormat(null, 16, FlxColor.WHITE);
		previewSprite.y = FlxG.height / 2 - previewSprite.height / 2;
		previewSprite.x = FlxG.width / 4 - previewSprite.width / 2;
        previewSprite.scrollFactor.set();
		add(previewSprite);
	}

	function createEditor()
	{
		// Clear previous editor elements
		for (child in members)
			if (child != infoText && child != jsonText && child != previewSprite && !(child is FlxButton))
				remove(child);

		// Create editor elements based on config type
		switch (currentConfig)
		{
			case "noteConfig":
				createNoteEditor();
			case "chartConfig":
				createChartEditor();
			case "defaultConfig":
				createGameSettingsEditor();
		}
	}

	function createNoteEditor()
	{
		var scaleStepper = new ExtendedFlxUINumericStepper(10, 530, 0.1, configData.dimensions.scale, 0.1, 2.0, 1);
		scaleStepper.name = "note_scale";
		scaleStepper.onChange = function(value:Float)
		{
			configData.dimensions.scale = value;
			updatePreview();
		};
		scaleStepper.scrollFactor.set();
		add(scaleStepper);

		var widthStepper = new ExtendedFlxUINumericStepper(10, 560, 1, configData.dimensions.width, 50, 300, 0);
		widthStepper.name = "note_width";
		widthStepper.onChange = function(value:Float)
		{
			configData.dimensions.width = value;
			updatePreview();
		};
		widthStepper.scrollFactor.set();
		add(widthStepper);
	}

	function createChartEditor()
	{
		var gridSizeStepper = new ExtendedFlxUINumericStepper(10, 530, 1, configData.gridSize, 10, 100, 0);
		gridSizeStepper.name = "chart_gridSize";
		gridSizeStepper.onChange = function(value:Float)
		{
			configData.gridSize = value;
			updatePreview();
		};
		gridSizeStepper.scrollFactor.set();
		add(gridSizeStepper);

		var uiBoxWidthStepper = new ExtendedFlxUINumericStepper(10, 560, 1, configData.ui.boxWidth, 100, 500, 0);
		uiBoxWidthStepper.name = "chart_uiBoxWidth";
		uiBoxWidthStepper.onChange = function(value:Float)
		{
			configData.ui.boxWidth = value;
			updatePreview();
		};
		uiBoxWidthStepper.scrollFactor.set();
		add(uiBoxWidthStepper);
	}

	function createGameSettingsEditor()
	{
		if (configData.performance != null && configData.performance.fpsCap != null)
		{
			var fpsCapStepper = new ExtendedFlxUINumericStepper(10, 530, 1, configData.performance.fpsCap.defaut, configData.performance.fpsCap.min,
				configData.performance.fpsCap.max, 0);
			fpsCapStepper.name = "game_fpsCap";
			fpsCapStepper.onChange = function(value:Float)
			{
				configData.performance.fpsCap.defaut = value;
				updatePreview();
			};
			fpsCapStepper.scrollFactor.set();
			add(fpsCapStepper);
		}

		if (configData.gameplay != null)
		{
			var downscrollCheck = new FlxUICheckBox(10, 560, null, null, "Downscroll", 100);
			downscrollCheck.checked = configData.gameplay.downscroll;
			downscrollCheck.callback = function()
			{
				configData.gameplay.downscroll = downscrollCheck.checked;
				updatePreview();
			};
			downscrollCheck.scrollFactor.set();
			add(downscrollCheck);
		}
	}

	function saveConfig()
	{
		try
		{
			var data = Json.stringify(configData, null, "  ");
			#if sys
			sys.io.File.saveContent('assets/preload/data/${currentConfig}.json', data);
			showMessage("Config saved successfully!");
			#else
			_file = new FileReference();
			_file.save(data, '${currentConfig}.json');
			#end
		}
		catch (e)
		{
			showError('Failed to save config: ${e.message}');
		}
	}

	function resetConfig()
	{
		switch (currentConfig)
		{
			case "noteConfig":
				configData = ConfigManager.getDefaultNoteConfig();
			case "chartConfig":
				configData = ConfigManager.getDefaultChartConfig();
			case "defaultConfig":
				configData = ConfigManager.getDefaultGameConfig();
		}
		updatePreview();
		createEditor();
		showMessage("Config reset to default values.");
	}

	function exportConfig()
	{
		try
		{
			var data = Json.stringify(configData, null, "  ");
			_file = new FileReference();
			_file.save(data, '${currentConfig}.json');
		}
		catch (e)
		{
			showError('Failed to export config: ${e.message}');
		}
	}

	function testConfig()
	{
		// Test current config values
		switch (currentConfig)
		{
			case "noteConfig":
				var testNote = new Note(0, 0, 0, false);
				// Test note creation with current config
				testNote.destroy();
				UIEffects.showToast("Note config test passed!", FlxColor.LIME);
			case "chartConfig":
				// Test chart settings
				if (configData.gridSize > 0 && configData.ui.boxWidth > 0)
                    UIEffects.showToast("Chart config validation passed!", FlxColor.LIME);
				else
					showError("Invalid chart dimensions!");
			case "defaultConfig":
				if (configData.performance != null && configData.performance.fpsCap != null)
				{
					var fps = configData.performance.fpsCap;
					if (fps.min <= fps.defaut && fps.defaut <= fps.max)
						UIEffects.showToast("Game settings validation passed!", FlxColor.LIME);
					else
						showError("Invalid FPS range!");
				}
				else
				{
					showError("Performance settings not found!");
				}
		}
	}

	function showMessage(text:String) {
        var message = UIEffects.showToast(text, FlxColor.GREEN);
        add(message);
    }

    function showError(text:String) {
        var error = UIEffects.showToast(text, FlxColor.RED);
        add(error);
        FlxG.camera.shake(0.01, 0.2);
    }

	override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }

        if (FlxG.keys.pressed.SHIFT) {
            if (FlxG.keys.justPressed.UP) modifyValue(0.1);
            else if (FlxG.keys.justPressed.DOWN) modifyValue(-0.1);
        }

        // Combine control key checks
        if (FlxG.keys.pressed.CONTROL) {
            if (FlxG.keys.justPressed.S) saveConfig();
            if (FlxG.keys.justPressed.R) loadCurrentConfig();
            if (FlxG.keys.justPressed.T) testConfig();
        }

        if (FlxG.mouse.wheel != 0)
            FlxG.camera.scroll.y -= FlxG.mouse.wheel * 20;
    }

	function modifyValue(change:Float)
	{
		switch (currentConfig)
		{
			case "noteConfig":
				configData.dimensions.scale += change;
				configData.dimensions.scale = Math.max(0.1, Math.min(2.0, configData.dimensions.scale));
				updatePreview();
			case "chartConfig":
				configData.gridSize += Std.int(change * 10);
				configData.gridSize = Std.int(Math.max(10, Math.min(100, configData.gridSize)));
				updatePreview();
			case "defaultConfig":
				if (configData.performance != null && configData.performance.fpsCap != null)
				{
					var fps = configData.performance.fpsCap;
					fps.defaut += Std.int(change * 10);
					fps.defaut = Std.int(Math.max(fps.min, Math.min(fps.max, fps.defaut)));
					updatePreview();
				}
		}
	}
}
