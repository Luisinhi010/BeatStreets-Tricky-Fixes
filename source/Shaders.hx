package;

// STOLEN FROM HAXEFLIXEL DEMO LOL
import openfl.Lib;
import flixel.system.FlxAssets.FlxShader;

using StringTools;

typedef ShaderEffect =
{
	var shader:Dynamic;
}

class NoAlphaEffect extends Effect
{
	public var shader:NoAlphaShader = new NoAlphaShader();

	public function new()
	{
	}
}

class NoAlphaShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		void main()
		{
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);

			if (color.a < 0.9)
				discard;
			else
				gl_FragColor = color;
		}')
	public function new()
	{
		super();
	}
}

class MosaicEffect extends Effect
{
	public var shader:MosaicShader = new MosaicShader();

	public var pixelSize(default, set):Float = 0;

	public var res:Array<Int> = [0, 0];

	function set_pixelSize(value:Float):Float
	{
		pixelSize = value;
		shader.pixelSize.value = [pixelSize];
		return value;
	}

	public function new(pixelSize:Float = 1)
	{
		this.pixelSize = pixelSize;
		updateShaderResolution(1);
		res = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
	}

	public function updateShaderResolution(zoom:Float):Void
	{
		var baseResolutionX = res[0] / zoom;
		var baseResolutionY = res[1] / zoom;
		shader.resolution.value = [baseResolutionX, baseResolutionY];
	}
}

class MosaicShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
	
		uniform vec2 resolution;
		uniform float pixelSize;
	
		void main()
		{
			if (pixelSize == 0.0)
			{
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
				return;
			}
			vec2 gridSize = vec2(pixelSize) / resolution.xy;
	
			vec2 gridOrigin = floor(openfl_TextureCoordv / gridSize) * gridSize;
			vec2 gridCenter = gridOrigin + gridSize * 0.5;
	
			float chromaOffset = gridCenter.x * 1 / resolution.x;
	
			vec2 rCoord = gridCenter + vec2(chromaOffset, 0.0);
			vec2 gCoord = gridCenter;
			vec2 bCoord = gridCenter - vec2(chromaOffset, 0.0);
	
			float r = texture2D(bitmap, rCoord).r;
			float g = texture2D(bitmap, gCoord).g;
			float b = texture2D(bitmap, bCoord).b;
			float a = texture2D(bitmap, gridCenter).a;
	
			gl_FragColor = vec4(r, g, b, a);
		}
	')
	public function new()
	{
		super();
	}
}

class ChromaticAberrationEffect extends Effect
{
	public var shader:ChromaticAberrationShader = new ChromaticAberrationShader();

	public var multiplier(default, set):Float = 0.01;

	function set_multiplier(value:Float):Float
	{
		multiplier = value;
		setChrome(value);
		return value;
	}

	public function new(offset:Float = 0.00):Void
	{
		multiplier = offset;
	}

	public function setChrome(chromeOffset:Float):Void
	{
		shader.rOffset.value = [chromeOffset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [chromeOffset * -1];
		shader.offset.value = [chromeOffset];
	}
}

class ChromaticAberrationShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		uniform float offset;

		uniform float rOffset;
		uniform float gOffset;
		uniform float bOffset;

		void main()
		{
			vec4 col1 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
			vec4 col2 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
			vec4 col3 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
			vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
			toUse.r = col1.r;
			toUse.g = col2.g;
			toUse.b = col3.b;

			gl_FragColor = toUse;
		}')
	public function new()
	{
		super();
	}
}

class TextureDistortionEffect extends Effect
{
	public var shader:TextureDistortionShader = new TextureDistortionShader();

	public var multiplier(default, set):Float = 0.2;

	function set_multiplier(value:Float):Float
	{
		multiplier = value;
		shader.multiplier.value = [multiplier];
		return value;
	}

	public function new(multiplier:Float = 0.2)
		this.multiplier = multiplier;
}

class TextureDistortionShader extends FlxFixedShader
{
	@:glFragmentSource('
	#pragma header
	
	uniform float multiplier;
	
	void main()
	{
		vec2 uv = openfl_TextureCoordv;
	
		vec2 offset = vec2(0.5, 0.5);
		vec2 crtDistortion = vec2(multiplier / (uv.x + offset.x), multiplier / (uv.y + offset.y));
	
		float d = length(uv - offset);
		vec2 distortedUv = uv + (uv - offset) * (d * d * d) * crtDistortion;
	
		vec2 mirroredUv;
		mirroredUv.x = distortedUv.x > 1.0 ? 2.0 - distortedUv.x : (distortedUv.x < 0.0 ? -distortedUv.x : distortedUv.x);
		mirroredUv.y = distortedUv.y > 1.0 ? 2.0 - distortedUv.y : (distortedUv.y < 0.0 ? -distortedUv.y : distortedUv.y);
	
		vec2 clampedUv = clamp(mirroredUv, 0.001, 0.998);
	
		vec4 color = texture2D(bitmap, clampedUv);
	
		gl_FragColor = color;
	}
	')
	public function new()
	{
		super();
	}
}

class VignetteBlurEffect extends Effect
{
	public var shader:VignetteBlurShader = new VignetteBlurShader();

	public var multiplier(default, set):Float = 1.0;

	function set_multiplier(value:Float):Float
	{
		multiplier = value;
		shader.multiplier.value = [multiplier];
		return value;
	}

	public function new(multiplier:Float = 1.0)
		this.multiplier = multiplier;
}

class VignetteBlurShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		uniform float multiplier;

		float blurAmount(vec2 uv) {
			vec2 center = vec2(0.5, 0.5);
			float distance = length(uv - center);
			
			float radius = 0.4;
			float strength = 0.4 * multiplier;

			return smoothstep(radius, radius + strength, distance);
		}

		void main() {
			vec2 uv = openfl_TextureCoordv.st;
			float amount = blurAmount(uv);

			vec4 color = vec4(0.0);
			for (int i = -2; i <= 2; i++) {
				for (int j = -2; j <= 2; j++) {
					color += texture2D(bitmap, uv + vec2(float(i), float(j)) * amount * 0.01);
				}
			}
			color /= 25.0;

			gl_FragColor = color;
		}
	')
	public function new()
	{
		super();
	}
}

class Effect
{
	public function setValue(shader:FlxShader, variable:String, value:Float)
	{
		Reflect.setProperty(Reflect.getProperty(shader, 'variable'), 'value', [value]);
	}
}
