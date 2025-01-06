package;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import openfl.utils.Assets;

class CloudSprite extends FlxSprite
{
    private var cloudShader:CloudShader;

    public var cloudColor:FlxColor = FlxColor.WHITE;
    public var cloudIntensity:Float = 1.0;
    public var cloudScale:Float = 1.0;

    public function new(x:Float, y:Float, width:Int, height:Int)
    {
        super(x, y);
        makeGraphic(width, height, FlxColor.TRANSPARENT);

        cloudShader = new CloudShader();
        this.shader = cloudShader;

        cloudShader.uCloudColor.value = [cloudColor.red, cloudColor.green, cloudColor.blue, cloudColor.alpha];
        cloudShader.uCloudIntensity.value = [cloudIntensity];
        cloudShader.uCloudScale.value = [cloudScale];
    }

    override public function draw():Void
    {
        super.draw();
    }

    function set_cloudColor(value:FlxColor):FlxColor
    {
        cloudColor = value;
        cloudShader.uCloudColor.value = [value.red, value.green, value.blue, value.alpha];
        return value;
    }

    function set_cloudIntensity(value:Float):Float
    {
        cloudIntensity = value;
        cloudShader.uCloudIntensity.value = [value];
        return value;
    }

    function set_cloudScale(value:Float):Float
    {
        cloudScale = value;
        cloudShader.uCloudScale.value = [value];
        return value;
    }
}

class CloudShader extends FlxFixedShader
{
    @:glFragmentSource('#pragma header

uniform vec4 uCloudColor = vec4(1.0, 1.0, 1.0, 1.0);
uniform float uCloudIntensity = 1.0;
uniform float uCloudScale = 1.0;
uniform float uTime = 0.0;

float noise(vec2 uv) {
    float n = sin(uv.x * 7.0 + uv.y * 3.0) + sin(uv.y * 5.0 + uv.x * 2.0);
    n += sin(uv.x * 13.0 + uv.y * 8.0) * 0.5;
    n += sin(uv.y * 11.0 + uv.x * 6.0) * 0.25;
    return n * 0.25 + 0.5;
}

void main() 
{
    vec2 uv = openfl_TextureCoordv * uCloudScale;
    
    // Add time to UV coordinates for scrolling animation
    uv += vec2(uTime * 0.1, uTime * 0.05); 

    float cloud = noise(uv);
    
    // Use smoothstep for smoother cloud edges
    cloud = smoothstep(0.3, 0.7, cloud); 

    // Adjust alpha based on cloud density
    float alpha = cloud * uCloudIntensity * uCloudColor.a;

    gl_FragColor = vec4(uCloudColor.rgb * cloud * uCloudIntensity, alpha);
}
    ')
    public function new()
    {
        super();
    }
}
