package;

import flixel.FlxG;
import openfl.display.ShaderParameter;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import lime.math.Vector4;

/**
 * FlxSprite subclass that applies a normal map effect for lighting.
 * This sprite uses a normal map to create dynamic lighting effects.
 * It allows adjusting the light direction, intensity, and normal map intensity.
 * The effect can be disabled for low-end devices.
 */
class NormalMapSprite extends FlxSprite
{
	/** The normal map BitmapData. */
	private var normalMap:BitmapData = null;
	/** The normal map shader. */
	private var normalShader:NormalMapShader = null;

	/** The light intensity multiplier. */
	public var lightMultiplier:Float = 0.1;
	/** The normal map intensity multiplier. */
	public var normalMultiplier:Float = 1;
	/** The light direction vector. */
	public var lightDirection:Vector4 = new Vector4(0.0, 0.0, 1.0, 1.0);

	/** The x-angle of the light direction in degrees. */
	public var angleX(default, set):Float = 0.0;
	/** The y-angle of the light direction in degrees. */
	public var angleY(default, set):Float = 0.0;

	private var _cachedLightMultiplier:Float = -1;
	private var _cachedNormalMultiplier:Float = -1;
	private var _cachedLightDirection:Vector4 = new Vector4();

	/**
	 * Creates a new NormalMapSprite with a normal map effect.
	 * 
	 * @param x The x-coordinate of the sprite.
	 * @param y The y-coordinate of the sprite.
	 * @param graphicPath The path to the sprite's graphic.
	 * @param normalMapPath The path to the normal map. If null or omitted, no normal mapping is applied.
	 */
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

	/**
	 * Initializes the normal map shader and sets the textures.
	 */
	private function initializeShader():Void
	{
		normalShader = new NormalMapShader();
		normalShader.uDiffuseMap.input = this.pixels;
		normalShader.uNormalMap.input = normalMap;
		this.shader = normalShader;
	}

	/**
	 * Sets the x-angle of the light direction.
	 * @param value The angle in degrees.
	 * @return The new angleX value.
	 */
	public function set_angleX(value:Float)
	{
		angleX = value % 360.0;
		setLightDirection(angleX, angleY);
		return angleX;
	}

	/**
	 * Sets the y-angle of the light direction.
	 * @param value The angle in degrees.
	 * @return The new angleY value.
	 */
	public function set_angleY(value:Float)
	{
		angleY = value % 360.0;
		setLightDirection(angleX, angleY);
		return angleY;
	}

	/**
	 * Draws the sprite with the normal map effect applied.
	 * Updates shader uniforms only if values have changed.
	 */
	override public function draw():Void
    {
        if (normalShader != null && normalMap != null && !FlxG.save.data.lowend)
        {
            if (_cachedLightMultiplier != lightMultiplier)
            {
                normalShader.uLightIntensity.value = [lightMultiplier];
                _cachedLightMultiplier = lightMultiplier;
            }

            if (_cachedNormalMultiplier != normalMultiplier)
            {
                normalShader.uNormalIntensity.value = [normalMultiplier];
                _cachedNormalMultiplier = normalMultiplier;
            }

            if (!_cachedLightDirection.equals(lightDirection))
            {
                normalShader.uLightDirection.value = [lightDirection.x, lightDirection.y, lightDirection.z];
                _cachedLightDirection.copyFrom(lightDirection);
            }
            normalShader.uAntiAliasing.value = [antialiasing];
        }
        super.draw();
    }

	/**
	 * Sets the light direction based on the given angles.
	 * @param angleX The x-angle in degrees.
	 * @param angleY The y-angle in degrees.
	 */
    public function setLightDirection(angleX:Float, angleY:Float):Void
    {
        var radX:Float = angleX * Math.PI / 180;
        var radY:Float = angleY * Math.PI / 180;

        var newLightDirection = new Vector4(Math.sin(radX), Math.sin(radY), Math.cos(radX) * Math.cos(radY));

        if (!_cachedLightDirection.equals(newLightDirection))
        {
            lightDirection.copyFrom(newLightDirection);
            normalShader.uLightDirection.value = [lightDirection.x, lightDirection.y, lightDirection.z];
            _cachedLightDirection.copyFrom(lightDirection);
        }
    }
}

/**
 * FlxShader for applying normal mapping.
 * This shader takes a diffuse map and a normal map as input to calculate lighting.
 * Lighting is calculated based on the light direction and intensity.
 * Anti-aliasing is supported for smoother edges.
 */
class NormalMapShader extends FlxFixedShader
{
	/**
	 * Fragment shader code for normal mapping.
	 * Decodes normal map data, calculates lighting, and applies anti-aliasing.
	 */
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

    vec2 texelSize = 1.0 / vec2(textureSize(uDiffuseMap, 0));

        if (uAntiAliasing)
        {
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
