package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import CharacterData.CharacterConfig;
import scripting.ScriptManager;

using StringTools;

class Character extends FlxSprite {
    public static var characterCache:Map<String, CharacterConfig> = new Map();
    public var isReady:Bool = false;
    public var stunned:Bool = false;
    public var animOffsets:Map<String, Array<Dynamic>>;
    public var debugMode:Bool = false;
    public var isPlayer:Bool = false;
    public var curCharacter:String = 'bf';
    public var holdTimer:Float = 0;
    public var iconColor:Array<Int> = [255, 0, 0];
    public var chromaticAberration:Shaders.ChromaticAberrationEffect;
    public var chromaticIntensity:Float = 0.0001;
    public var charData:CharacterConfig;
    public var scriptManager:ScriptManager;

    public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDebug:Bool = false) {
        super(x, y);
        initializeCharacter(character, isPlayer, isDebug);
    }

    private inline function initializeCharacter(character:String, isPlayer:Bool, isDebug:Bool):Void {
        animOffsets = new Map();
        curCharacter = character;
        this.isPlayer = isPlayer;
        debugMode = isDebug;
        setupCharacter();
    }

    private inline function setupCharacter():Void {
        charData = loadCharacterData(curCharacter);
        if (charData == null) return;

        loadCharacterGraphics();
        setupAnimations();
        applyCharacterConfig();
        executeScriptCallback("onCreateAfter");
    }

    private inline function executeScriptCallback(callbackName:String, ?args:Array<Dynamic>):Dynamic {
        return scriptManager?.callFunction(callbackName, args ?? [this]);
    }

    public static function preloadCharacter(char:String):Void {
        if (!characterCache.exists(char)) {
            var data = Paths.getCharacterData(char);
            if (data != null) characterCache.set(char, data.config);
        }
    }

    private function loadCharacterData(char:String):CharacterConfig {
        if (characterCache.exists(char)) return characterCache.get(char);

        var data = Paths.getCharacterData(char);
        if (data == null || data.config == null) {
            trace('Invalid character data for: $char');
            return getDefaultCharacterData();
        }

        if (data.script != null && data.script.length > 0) {
            initScript(data.script, char);
        }

        characterCache.set(char, data.config);
        return data.config;
    }

    private inline function initScript(scriptCode:String, char:String):Void {
        scriptManager = new ScriptManager();
        scriptManager.setVariable("character", this);
        if (!scriptManager.loadScript(scriptCode, 'characters/${char}.hx')) {
            scriptManager = null;
        } else {
            executeScriptCallback("onCreate"); // Call onCreate if script loaded successfully
        }
    }


    private function getDefaultCharacterData():CharacterConfig {
        return {
            name: "bf",
            asset: "BOYFRIEND",
            library: "shared",
            iconColor: [171, 22, 74],
            scale: 1.0,
            antialias: true,
            flipX: true,
            animations: [],
            offsets: new Map()
        };
    }

	private function loadCharacterGraphics() {
        var mainAsset = charData.asset;
        // Use single if-else chain for clarity
        if (charData.caching) {
            var mainSprite = CachedFrames.getCachedGraphic('char_${charData.name}', mainAsset);
            var tex = FlxAtlasFrames.fromSparrow(mainSprite, Paths.file('images/${mainAsset}.xml', charData.library));

            if (charData.additionalSprites != null) { // Simplified null check
                for (sprite in charData.additionalSprites) {
                    var additionalTex = CachedFrames.fromSparrow(sprite.id, sprite.path);
                    if (additionalTex != null) tex.addAtlas(additionalTex);
                }
            }
            frames = tex;
        } else {
            frames = Paths.getSparrowAtlas(mainAsset, charData.library);
        }
    }

    private function setupAnimations():Void {
        for (anim in charData.animations) {
            if (anim.indices != null)
                animation.addByIndices(anim.name, anim.prefix, anim.indices, "", anim.fps, anim.loop);
            else
                animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);

            if (anim.offsets != null) addOffset(anim.name, anim.offsets[0], anim.offsets[1]);
        }
    }

    private function applyCharacterConfig():Void {
        setGraphicSize(Std.int(width * charData.scale));
        updateHitbox();
        antialiasing = charData.antialias;
        if (FlxG.save.data.lowend) antialiasing = false;

        flipX = charData.flipX;
        if (isPlayer) {
            flipX = !flipX;
            if (!curCharacter.startsWith('bf') && !curCharacter.toLowerCase().contains('death')) {
                swapAnimationFrames('singLEFT', 'singRIGHT');
                if (animation.getByName('singRIGHTmiss') != null) swapAnimationFrames('singLEFTmiss', 'singRIGHTmiss');
            }
        }

        iconColor = charData.iconColor;

        if (charData.chromaticIntensity > 0 && !FlxG.save.data.lowend) {
            chromaticIntensity = charData.chromaticIntensity;
            chromaticAberration = new Shaders.ChromaticAberrationEffect(chromaticIntensity);
            shader = chromaticAberration.shader;
        }

        playAnim(charData.specialBehavior == "gf" ? 'dance' : 'idle');
    }

    inline function swapAnimationFrames(anim1:String, anim2:String):Void {
        var anim1Frames = animation.getByName(anim1).frames;
        var anim2Frames = animation.getByName(anim2).frames;
        animation.getByName(anim1).frames = anim2Frames;
        animation.getByName(anim2).frames = anim1Frames;
    }


    override function update(elapsed:Float):Void {
        executeScriptCallback("onUpdate", [elapsed]);
        super.update(elapsed);

        var curAnim = animation.curAnim;
        if (curAnim == null) return;

        var holdDuration = Conductor.stepCrochet * 0.004;

        if (isPlayer)      updatePlayerAnimation(elapsed, holdDuration);
        else                updateNPCAnimation(elapsed, holdDuration, curAnim);
    }

    function updatePlayerAnimation(elapsed:Float, holdDuration:Float):Void {
		if (animation.curAnim.name.startsWith('sing')) {
			holdTimer += elapsed;
		} else {
			holdTimer = 0;
		}
	
		if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished) {
			playAnim('idle', true, false, 10);
		}
	}
	
	function updateNPCAnimation(elapsed:Float, holdDuration:Float, curAnim:FlxBaseAnimation):Void {
		if (curAnim.name.startsWith('sing')) {
			holdTimer += elapsed;
			if (holdTimer >= holdDuration) {
				dance();
				holdTimer = 0;
			}
		}
	}
    private var danced:Bool = false;
    public function dance(force:Bool = false):Void {

        if (!debugMode) {
            switch (curCharacter) {
                case 'gf' | 'gf-upside' | 'gf-hell':
                    danced = !danced;
                    playAnim(danced ? 'danceRight' : 'danceLeft', force);
                default:
                    playAnim('idle', force);
            }
        }
    }

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
        animation.play(AnimName, Force, Reversed, Frame);

        var daOffset = animOffsets.get(AnimName);
        if (daOffset != null) offset.set(daOffset[0], daOffset[1]); else offset.set(0, 0);

        if (charData.specialBehavior == 'gf') {
            danced = switch (AnimName) {
                case 'singLEFT': true;
                case 'singRIGHT': false;
                case 'singUP', 'singDOWN': !danced;
                default: danced;
            };
        }

        executeScriptCallback("onPlayAnim", [this, AnimName]);
    }

    public inline function addOffset(name:String, x:Float = 0, y:Float = 0):Void {
        animOffsets.set(name, [x, y]);
    }

    public function switchCharacter(newChar:String):Bool {
        try {
            initializeCharacter(newChar, isPlayer, debugMode);
            return true;
        } catch (e) {
            trace('Failed to switch character to $newChar: ${e.message}');
            return false;
        }
    }

    override function destroy():Void {
        if (scriptManager != null) {
            executeScriptCallback("onDestroy");
            scriptManager.destroy();
            scriptManager = null;
        }
        super.destroy();
    }
}
