package;

import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.Lib;
import flixel.util.FlxAxes;
import lime.utils.Assets;
import flixel.FlxSprite;

using StringTools;

class LuisSprite extends FlxSprite // the only reason i created a new object is because of the shader
{
	var ditherShader:DitherShader;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		ditherShader = new DitherShader();
		this.shader = ditherShader;
	}

	override public function draw():Void
	{
		ditherShader.seed.value = [Math.random() * 10];
		super.draw();
	}
}

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

            if (granularEnabled) {
                float noise = rand(openfl_TextureCoordv + seed);
                if (color.a < 0.5 + noise * (1.0 - 0.5)) {
                    discard;
                }
            }

            float dither = rand(openfl_TextureCoordv + seed) - 0.5;
            color.rgb += dither * (multiplier * color.a);

            gl_FragColor = color;
        }
')
	public function new()
	{
		super();
	}
}
