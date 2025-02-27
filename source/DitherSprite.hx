package;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

/**
 * A FlxSprite subclass that applies a dithering effect.
 * This sprite uses a shader to create a retro-style dithering pattern
 * that can be customized per animation.
 */
class DitherSprite extends FlxSprite
{
    /** The dither effect shader */
    private var ditherShader:DitherShader;
    /** Random seed for dither pattern */
    private var randomSeed:Float;
    /** Map of animation-specific dither multipliers */
    private var animationMultipliers:Map<String, Float>;
    /** Whether the shader is currently active */
    private var isShaderActive:Bool = false;

    public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
    {
        animationMultipliers = new Map<String, Float>();
        super(X, Y, SimpleGraphic);
        ditherShader = new DitherShader();
        this.shader = ditherShader;
        randomSeed = 0;
    }

    /**
     * Sets a specific dither multiplier for an animation.
     * @param animName The name of the animation
     * @param multiplier The dither intensity multiplier (0.0 to 1.0)
     */
    public function setAnimationDitherMultiplier(animName:String, multiplier:Float):Void {
        animationMultipliers.set(animName, multiplier);
    }

    /**
     * Enables or disables the dither shader.
     * @param enabled Whether the shader should be active
     */
    public function setShaderEnabled(enabled:Bool):Void {
        isShaderActive = enabled;
        this.shader = enabled ? ditherShader : null;
    }

    override public function draw():Void
    {
        if (ditherShader == null || !isShaderActive) {
            super.draw();
            return;
        }
        
        if (animation != null && animation.curAnim != null) {
            var animName = animation.curAnim.name;
            var multiplier = animationMultipliers.exists(animName) ? 
                           animationMultipliers.get(animName) : 0.2;
            
            ditherShader.multiplier.value = [multiplier];
            randomSeed = FlxG.random.float(0, 1);
            ditherShader.seed.value = [randomSeed];
        }
        
        super.draw();
    }

    override public function destroy():Void
    {
        animationMultipliers = null;
        ditherShader = null;
        shader = null;
        super.destroy();
    }
}

/**
 * Shader class that implements the dithering effect.
 * Uses a random noise pattern to create a dithered appearance.
 */
class DitherShader extends FlxFixedShader
{
    @:glFragmentSource('
    #pragma header

        uniform float multiplier = 0.2;
        uniform float seed;
        uniform bool granularEnabled = true;

        float rand(vec2 co){
            return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
        }

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            float premult = min(multiplier, 1.0) * color.a;

            float noise = rand(openfl_TextureCoordv + seed);

            if (granularEnabled) {
                if (color.a < 0.5 + noise * 0.5) {
                    discard;
                }
            }

            float dither = noise - 0.5;
            color.rgb += dither * premult;

            gl_FragColor = color;
        }
    ')
    public function new()
    {
        super();
    }
}
