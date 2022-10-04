package;

// STOLEN FROM HAXEFLIXEL DEMO LOL
import openfl.Lib;
import flixel.system.FlxAssets.FlxShader;

using StringTools;

typedef ShaderEffect =
{
	var shader:Dynamic;
}

class ChromaticAberrationEffect extends Effect
{
	public var shader:ChromaticAberrationShader;

	public function new(offset:Float = 0.00)
	{
		shader = new ChromaticAberrationShader();
		shader.rOffset.value = [offset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [-offset];
		shader.offset.value = [offset];
	}

	public function setChrome(chromeOffset:Float):Void
	{
		shader.rOffset.value = [chromeOffset];
		shader.gOffset.value = [0.0];
		shader.bOffset.value = [chromeOffset * -1];
		shader.offset.value = [chromeOffset];
	}

	public function getChrome():Float
	{
		return shader.offset.value[0];
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
			//float someshit = col4.r + col4.g + col4.b;

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

	public var animated:Bool = true;

	public function new(offset:Float = 2, distortion:Float = 6, animated:Bool = true)
	{
		shader.offset.value = [offset];
		shader.distortion.value = [distortion];
		this.animated = animated;
		shader.iTime.value = [0];
		shader.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
	}

	public function update(elapsed:Float)
	{
		if (this == null)
			return;
		shader.iTime.value[0] += animated ? elapsed / 4 : 0;
		shader.iResolution.value = [Lib.current.stage.stageWidth, Lib.current.stage.stageHeight];
	}

	public function setOfsset(offset:Float = 2)
	{
		shader.offset.value[0] = offset;
	}

	public function setDistortion(distortion:Float = 6)
	{
		shader.distortion.value[0] = distortion;
	}

	public function setAnimated(animated:Bool = true)
	{
		this.animated = animated;
	}
}

class TextureDistortionShader extends FlxFixedShader
{
	@:glFragmentSource('
    #pragma header

    uniform float iTime;
    uniform vec3 iResolution;
	uniform float offset = 2;
	uniform float distortion = 6;

	void main()
	{
		vec2 uv =  openfl_TextureCoordv;
		
		//uv.y = -1.0 - uv.y;
		
		uv.x += cos(uv.y * distortion + iTime * offset) /100.0;
		uv.y += sin(uv.x * distortion + iTime * offset) /100.0;
		uv.x -= cos(uv.y * distortion + iTime * offset) /100.0;
		uv.x -= cos(uv.x * distortion + iTime * offset) /100.0;
		
		vec4 color = texture2D(bitmap, uv);
		
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
