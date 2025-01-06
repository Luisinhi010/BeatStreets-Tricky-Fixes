package;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class LuisSprite extends FlxSprite // the only reason i created a new object is because of the shader
{
	var ditherShader:DitherShader;
	private var randomSeed:Float;

	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);
		ditherShader = new DitherShader();
		this.shader = ditherShader;
		randomSeed = 0;
	}

	override public function draw():Void
	{
		randomSeed = FlxG.random.float();
		ditherShader.seed.value = [randomSeed];
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
            float premult = multiplier * color.a;

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
