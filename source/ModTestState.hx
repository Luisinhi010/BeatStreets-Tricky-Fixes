package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import scripting.ScriptHandler;
import ModManager;
import sys.FileSystem;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.FlxCamera;

using StringTools;

class ModTestState extends MusicBeatState
{
    private var bgGroup:FlxGroup;
    private var contentGroup:FlxGroup;
    private var uiGroup:FlxGroup;
    var infoText:FlxText;
    var testResults:FlxText;
    
    override function create()
    {
        super.create();

        bgGroup = new FlxGroup();
        contentGroup = new FlxGroup();
        uiGroup = new FlxGroup();

        add(bgGroup);
        add(contentGroup);
        add(uiGroup);

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF2C2C2C);
        bg.alpha = 0.8;
        bgGroup.add(bg);

        // Painéis base
        var mainPanel = new FlxSprite(10, 40).makeGraphic(FlxG.width - 20, FlxG.height - 50, 0xFF2A2A2A);
        mainPanel.scrollFactor.set();
        bgGroup.add(mainPanel);

        infoText = new FlxText(10, 10, FlxG.width - 20, "Mod Testing Menu");
        infoText.setFormat(null, 24, FlxColor.WHITE, CENTER);
        infoText.scrollFactor.set();
        uiGroup.add(infoText);

        testResults = new FlxText(10, 50, FlxG.width - 20);
        testResults.setFormat(null, 16, FlxColor.WHITE);
        testResults.scrollFactor.set();
        uiGroup.add(testResults);

        createTestButtons();
        createHelpTooltip();
    }

    function createTestButtons()
    {
        var buttonData:Array<{label:String, callback:()->Void, key:String}> = [
            {label: "Test All", callback: testAllMods, key: "T"},
            {label: "Test Scripts", callback: () -> testScripts(), key: "S"},
            {label: "Test Assets", callback: () -> testAssets(), key: "A"},
            {label: "Test Characters", callback: () -> FlxG.switchState(new CharacterTestState()), key: "C"},
            {label: "Reload Mods", callback: reloadMods, key: "R"},
            {label: "Back", callback: () -> FlxG.switchState(new MainMenuState()), key: "ESC"}
        ];

        var buttonY = 120.0;
        for (data in buttonData)
        {
            var btn = createStylizedButton(
                FlxG.width - 210, 
                buttonY, 
                data.label, 
                data.callback,
                data.key
            );
            buttonY += 40;
        }
    }

    function createStylizedButton(x:Float, y:Float, label:String, callback:()->Void, hotkey:String):FlxButton {
        var btn = new FlxButton(x, y, label, callback);
        btn.setGraphicSize(200, 30);
        btn.updateHitbox();
        btn.label.setFormat(null, 12, FlxColor.WHITE);
        btn.scrollFactor.set();
        
        var hotkeyText = new FlxText(btn.x, btn.y + btn.height, btn.width, '[$hotkey]');
        hotkeyText.alignment = CENTER;
        hotkeyText.color = FlxColor.GRAY;
        hotkeyText.size = 10;
        hotkeyText.scrollFactor.set();
        uiGroup.add(hotkeyText);

        btn.onOver.callback = () -> {
            FlxTween.tween(btn.scale, {x: 1.1, y: 1.1}, 0.1, {ease: FlxEase.quadOut});
            btn.color = FlxColor.fromRGB(200, 200, 200);
        };
        btn.onOut.callback = () -> {
            FlxTween.tween(btn.scale, {x: 1.0, y: 1.0}, 0.1, {ease: FlxEase.quadOut});
            btn.color = FlxColor.WHITE;
        };

        uiGroup.add(btn);
        return btn;
    }

    function testAllMods()
    {
        var results = "";
        var totalTests = 0;
        var passedTests = 0;

        // Test mod loading
        try {
            ModManager.loadMods();
            results += "✓ Mod loading successful\n";
            passedTests++;
        } catch(e) {
            results += "✗ Mod loading failed: " + e + "\n";
        }
        totalTests++;

        // Test scripts
        try {
            var scriptTests = testScripts(false);
            results += scriptTests.results;
            totalTests += scriptTests.total;
            passedTests += scriptTests.passed;
        } catch(e) {
            results += "✗ Script testing failed: " + e + "\n";
        }

        // Test assets
        try {
            var assetTests = testAssets(false);
            results += assetTests.results;
            totalTests += assetTests.total;
            passedTests += assetTests.passed;
        } catch(e) {
            results += "✗ Asset testing failed: " + e + "\n";
        }

        results += '\nTotal Tests: $totalTests\nPassed: $passedTests\nFailed: ${totalTests - passedTests}';
        showResults(results);
    }

    function testScripts(?showOutput:Bool = true)
    {
        var results = "\n= Script Tests =\n";
        var totalTests = 0;
        var passedTests = 0;

        try {
            // Test script loading
            @:privateAccess
            if (ScriptHandler.scripts != null) {
                results += "✓ Scripts system initialized\n";
                passedTests++;
            } else {
                results += "✗ Scripts system not initialized\n";
            }
            totalTests++;


            if (ScriptHandler.scripts != null) {
                for (scriptId in ScriptHandler.scripts.keys()) {
                    try {
                        var script = ScriptHandler.scripts.get(scriptId);
                        if (script != null) {
                            script.callFunction("onTest", []);
                            createTestEffects(true, FlxG.width - 40, 60 + totalTests * 30);
                            results += '✓ Script executed: $scriptId\n';
                            passedTests++;
                        } else {
                            createTestEffects(false, FlxG.width - 40, 60 + totalTests * 30);
                            results += '✗ Script is null: $scriptId\n';
                        }
                    } catch(e) {
                        createTestEffects(false, FlxG.width - 40, 60 + totalTests * 30);
                        results += '✗ Script error: $scriptId - $e\n';
                    }
                    totalTests++;
                }
            }
        } catch(e) {
            results += "✗ Fatal script test error: " + e + "\n";
            totalTests++;
        }

        if (showOutput)
            showResults(results);

        return {results: results, total: totalTests, passed: passedTests};
    }

    function testAssets(?showOutput:Bool = true)
    {
        var results = "\n= Asset Tests =\n";
        var totalTests = 0;
        var passedTests = 0;

        try {
            if (ModManager.activeMods == null) {
                results += "✗ No mods loaded\n";
                if (showOutput) showResults(results);
                return {results: results, total: 1, passed: 0};
            }

            for (mod in ModManager.activeMods) {
                if (mod == null || mod.path == null) continue;

                var imageDir = mod.path + "images/";
                if (FileSystem.exists(imageDir)) {
                    testImageDirectory(imageDir, mod.name, results, totalTests, passedTests);
                }

                var soundDir = mod.path + "sounds/";
                if (FileSystem.exists(soundDir)) {
                    testSoundDirectory(soundDir, mod.name, results, totalTests, passedTests);
                }

                var scriptDir = mod.path + "scripts/";
                if (FileSystem.exists(scriptDir)) {
                    testScriptDirectory(scriptDir, mod.name, results, totalTests, passedTests);
                }
            }
        } catch(e) {
            results += "✗ Fatal asset test error: " + e + "\n";
        }

        if (showOutput)
            showResults(results);

        return {results: results, total: totalTests, passed: passedTests};
    }

    private function testImageDirectory(dir:String, modName:String, results:String, totalTests:Int, passedTests:Int) {
        try {
            for (file in FileSystem.readDirectory(dir)) {
                if (!file.endsWith(".png")) continue;
                
                try {
                    var path = dir + file;
                    BitmapData.fromFile(path);
                    results += '✓ Image loaded: $modName/$file\n';
                    passedTests++;
                } catch(e) {
                    results += '✗ Image failed: $modName/$file - $e\n';
                }
                totalTests++;
            }
        } catch(e) {
            results += '✗ Error reading image directory: $modName - $e\n';
        }
    }

    private function testSoundDirectory(dir:String, modName:String, results:String, totalTests:Int, passedTests:Int) {
        try {
            for (file in FileSystem.readDirectory(dir)) {
                if (!file.endsWith(".ogg")) continue;
                
                try {
                    var path = dir + file;
                    Sound.fromFile(path);
                    results += '✓ Sound loaded: $modName/$file\n';
                    passedTests++;
                } catch(e) {
                    results += '✗ Sound failed: $modName/$file - $e\n';
                }
                totalTests++;
            }
        } catch(e) {
            results += '✗ Error reading sound directory: $modName - $e\n';
        }
    }

    private function testScriptDirectory(dir:String, modName:String, results:String, totalTests:Int, passedTests:Int) {
        try {
            for (file in FileSystem.readDirectory(dir)) {
                if (!file.endsWith(".hx")) continue;
                
                try {
                    var path = dir + file;
                    var script = sys.io.File.getContent(path);
                    
                    var parser = new hscript.Parser();
                    parser.allowTypes = parser.allowJSON = true;
                    parser.parseString(script);
                    
                    results += '✓ Script parsed: $modName/$file\n';
                    passedTests++;
                } catch(e) {
                    results += '✗ Script failed: $modName/$file - $e\n';
                }
                totalTests++;
            }
        } catch(e) {
            results += '✗ Error reading script directory: $modName - $e\n';
        }
    }
    
    function reloadMods()
    {
        Main.reloadMods();
        FlxG.resetState();
    }

    function showResults(text:String)
    {
        UIEffects.createTransition(() -> {
            testResults.text = text;
            testResults.alpha = 0;
            FlxTween.tween(testResults, {alpha: 1}, 0.3);
            
            // Efeito de shake suave
            FlxG.camera.shake(0.003, 0.2);
        });
    }

    function createTestEffects(success:Bool, x:Float, y:Float) {
        UIEffects.createStatusEffect(success, x, y);
    }

    function createHelpTooltip() {
        var tooltip = new FlxText(10, FlxG.height - 40, FlxG.width - 20,
            "CTRL+R: Reload Mods | CTRL+T: Test All | ESC: Back to Menu | Mouse Wheel: Scroll");
        tooltip.setFormat(null, 12, FlxColor.WHITE, CENTER);
        tooltip.alpha = 0.7;
        tooltip.scrollFactor.set();
        uiGroup.add(tooltip);
        
        FlxTween.tween(tooltip, {alpha: 0.4}, 1, {
            type: PINGPONG,
            ease: FlxEase.sineInOut
        });
    }

    function showError(message:String) {
        var errorBg = new FlxSprite(0, 0).makeGraphic(FlxG.width, 30, FlxColor.RED);
        errorBg.alpha = 0;
        errorBg.scrollFactor.set();
        uiGroup.add(errorBg);
        
        var errorText = new FlxText(0, 5, FlxG.width, message);
        errorText.setFormat(null, 16, FlxColor.WHITE, CENTER);
        errorText.alpha = 0;
        errorText.scrollFactor.set();
        uiGroup.add(errorText);
        
        FlxTween.tween(errorBg, {alpha: 0.3}, 0.3, {ease: FlxEase.quartOut});
        FlxTween.tween(errorText, {alpha: 1}, 0.3, {
            ease: FlxEase.quartOut,
            onComplete: function(twn:FlxTween) {
                new FlxTimer().start(2, function(tmr:FlxTimer) {
                    FlxTween.tween(errorBg, {alpha: 0}, 0.3);
                    FlxTween.tween(errorText, {alpha: 0}, 0.3, {
                        onComplete: function(twn:FlxTween) {
                            errorBg.destroy();
                            errorText.destroy();
                        }
                    });
                });
            }
        });
        
        FlxG.camera.shake(0.01, 0.2);
    }

    function showTestEffect(success:Bool, x:Float, y:Float) {
        var effects = UIEffects.createStatusEffect(success, x, y);
        for (effect in effects)
            uiGroup.add(effect);
    }

    function showToast(message:String) {
        var toast = UIEffects.showToast(message);
        uiGroup.add(toast);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.ESCAPE)
            FlxG.switchState(new MainMenuState());

        // Scroll test results
        if (FlxG.mouse.wheel != 0)
            testResults.y += FlxG.mouse.wheel * 20;
    }
}
