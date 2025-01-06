package;

// STOLEN FROM HAXEFLIXEL DEMO LOL
import openfl.Lib;
import flixel.system.FlxAssets.FlxShader;

using StringTools;

typedef ShaderEffect =
{
	var shader:Dynamic;
}

class GammaCorrectionEffect
{
	public var shader:GammaCorrectionShader = new GammaCorrectionShader();

	public var gamma(default, set):Float;

	function set_gamma(value:Float = 1):Float
	{
		gamma = value;
		shader.gamma.value = [gamma];
		return value;
	}

	public function new(gamma:Float = 1)
	{
		this.gamma = gamma;
	}
}

class GammaCorrectionShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		uniform float gamma;

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec3 linearColor = pow(color.rgb, vec3(gamma));
			gl_FragColor = vec4(linearColor, color.a);
		}
	')
	public function new()
	{
		super();
	}
}

class NoAlphaShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header
		
		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

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

class MosaicEffect
{
	public var shader:MosaicShader = new MosaicShader();

	public var pixelSize(default, set):Float = 0;

	public var res:Array<Int> = [0, 0];

	function set_pixelSize(value:Float):Float
	{
		pixelSize = value;
		shader.pixelSize.value = [value];
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
		shader.resolution.value = [res[0] / zoom, res[1] / zoom];
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
				gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
				return;
			}
			vec2 gridSize = vec2(pixelSize) / resolution.xy;

			vec2 gridOrigin = floor(openfl_TextureCoordv / gridSize) * gridSize;
			vec2 gridCenter = gridOrigin + gridSize * pixelSize * 0.5;

			float chromaOffset = gridCenter.x / resolution.x;

			vec2 rCoord = gridCenter + vec2(chromaOffset, 0.0);
			vec2 gCoord = gridCenter;
			vec2 bCoord = gridCenter - vec2(chromaOffset, 0.0);

			float r = flixel_texture2D(bitmap, rCoord).r;
			float g = flixel_texture2D(bitmap, gCoord).g;
			float b = flixel_texture2D(bitmap, bCoord).b;
			float a = flixel_texture2D(bitmap, gridCenter).a;

			gl_FragColor = vec4(r, g, b, a);
		}
	')
	public function new()
	{
		super();
	}
}

class ChromaticAberrationEffect
{
	public var shader:ChromaticAberrationShader = new ChromaticAberrationShader();

	public var multiplier(default, set):Float = 0.01;
	public var angle(default, set):Float = 0.0;

	function set_multiplier(value:Float):Float
	{
		multiplier = value;
		setChrome(value);
		return value;
	}

	function set_angle(value:Float):Float
	{
		angle = value;
		setChrome(multiplier);
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
		shader.angle.value = [angle];
	}
}

class ChromaticAberrationShader extends FlxFixedShader
{
	@:glFragmentSource('
		#pragma header

		uniform float offset;
		uniform float angle;
		uniform float rOffset;
		uniform float gOffset;
		uniform float bOffset;

		void main()
		{
			vec4 col = flixel_texture2D(bitmap, openfl_TextureCoordv);
			vec2 coord = openfl_TextureCoordv.st;

			float sinAngle = sin(angle);
			float cosAngle = cos(angle);
			vec2 rCoord = coord - vec2(rOffset * cosAngle, rOffset * sinAngle);
			vec2 gCoord = coord - vec2(gOffset * cosAngle, gOffset * sinAngle);
			vec2 bCoord = coord - vec2(bOffset * cosAngle, bOffset * sinAngle);

			float r = flixel_texture2D(bitmap, rCoord).r;
			float g = flixel_texture2D(bitmap, gCoord).g;
			float b = flixel_texture2D(bitmap, bCoord).b;
			float a = flixel_texture2D(bitmap, bCoord).a;

			gl_FragColor = vec4(r, g, b, a);
		}
	')
	public function new()
	{
		super();
	}
}

class TextureDistortionEffect
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
	
		vec4 color = flixel_texture2D(bitmap, clampedUv);
	
		gl_FragColor = color;
	}
	')
	public function new()
	{
		super();
	}
}

class VignetteBlurEffect
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
					color += flixel_texture2D(bitmap, uv + vec2(float(i), float(j)) * amount * 0.01);
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
