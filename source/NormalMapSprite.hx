package;

import flixel.FlxG;
import openfl.display.ShaderParameter;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import lime.math.Vector4;

class NormalMapSprite extends FlxSprite
{
	private var normalMap:BitmapData = null;
	private var normalShader:NormalMapShader = null;

	public var lightMultiplier:Float = 0.1;
	public var normalMultiplier:Float = 1;
	public var lightDirection:Vector4 = new Vector4(0.0, 0.0, 1.0, 1.0);

	public var angleX(default, set):Float = 0.0;
	public var angleY(default, set):Float = 0.0;

	public function new(x:Float, y:Float, graphicPath, ?normalMapPath)
	{
		super(x, y);
		try
		{
			loadGraphic(graphicPath);
			if (normalMapPath != null && !FlxG.save.data.lowend)
			{
				normalMap = (FlxG.bitmap.add(normalMapPath)).bitmap;
				initializeShader();
			}
		}
		catch (e:Dynamic)
		{
			trace("Error creating NormalMapSprite: " + e.error);
		}
	}

	private function initializeShader():Void
	{
		normalShader = new NormalMapShader();
		normalShader.data.uDiffuseMap.input = this.pixels;
		normalShader.data.uNormalMap.input = normalMap;
		this.shader = normalShader;
	}

	public function set_angleX(value:Float)
	{
		angleX = value % 360.0;
		setLightDirection(angleX, angleY);
		return angleX;
	}

	public function set_angleY(value:Float)
	{
		angleY = value % 360.0;
		setLightDirection(angleX, angleY);
		return angleY;
	}

	override public function draw():Void
	{
		if (normalShader != null && normalMap != null && !FlxG.save.data.lowend)
		{
			normalShader.uDiffuseMap.input = this.pixels;
			normalShader.uNormalMap.input = normalMap;
			normalShader.uLightIntensity.value = [lightMultiplier];
			normalShader.uNormalIntensity.value = [normalMultiplier];
		}
		super.draw();
	}

	public function setLightDirection(angleX:Float, angleY:Float):Void
	{
		var radX:Float = angleX * Math.PI / 180;
		var radY:Float = angleY * Math.PI / 180;

		lightDirection.x = Math.sin(radX);
		lightDirection.y = Math.sin(radY);
		lightDirection.z = Math.cos(radX) * Math.cos(radY);
		normalShader.uLightDirection.value = [lightDirection.x, lightDirection.y, lightDirection.z];
	}
}

class NormalMapShader extends FlxFixedShader
{
	@:glFragmentSource('
	#pragma header
	#pragma multisample

	uniform sampler2D uDiffuseMap;
	uniform sampler2D uNormalMap;
	uniform vec3 uLightDirection = vec3(0.5, 0.5, 0.5);
	uniform float uLightIntensity = 0.1;
	uniform float uNormalIntensity = 1.0;
	uniform bool uAntiAliasing = true;

	vec3 decodeNormal(vec3 normal) {
		return vec3(normal.x * 2.0 - 1.0, normal.y * 2.0 - 1.0, normal.z * 2.0 - 1.0);
	}

	float calculateLighting(vec3 normal, vec3 lightDir) {
		return max(dot(normal, lightDir), 0.0);
	}

	void main() 
	{
		vec4 baseColor = texture2D(uDiffuseMap, openfl_TextureCoordv);
		vec3 normal = decodeNormal(texture2D(uNormalMap, openfl_TextureCoordv).rgb);
		normal *= uNormalIntensity;
		float lighting = calculateLighting(normal, uLightDirection);

		float mask = step(0.05, length(baseColor.rgb));
		vec4 finalColor = vec4(baseColor.rgb + (lighting * uLightIntensity), baseColor.a);

		if (uAntiAliasing) //hacking...
		{
			vec2 texelSize = 1.0 / vec2(textureSize(uDiffuseMap, 0));
			vec4 color = texture2D(uDiffuseMap, openfl_TextureCoordv);
			vec4 colorNW = texture2D(uDiffuseMap, openfl_TextureCoordv + vec2(-texelSize.x, -texelSize.y));
			vec4 colorNE = texture2D(uDiffuseMap, openfl_TextureCoordv + vec2(texelSize.x, -texelSize.y));
			vec4 colorSW = texture2D(uDiffuseMap, openfl_TextureCoordv + vec2(-texelSize.x, texelSize.y));
			vec4 colorSE = texture2D(uDiffuseMap, openfl_TextureCoordv + vec2(texelSize.x, texelSize.y));
			finalColor.rgb = mix(finalColor.rgb, (colorNW.rgb + colorNE.rgb + colorSW.rgb + colorSE.rgb) / 4.0, 0.5);
		}

		gl_FragColor = mix(baseColor, finalColor, mask);
	}
')
	public function new()
	{
		super();
	}
}
