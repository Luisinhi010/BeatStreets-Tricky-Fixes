package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

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
	}

	override public function draw():Void
	{
		cloudShader.uCloudColor.value = [cloudColor.red, cloudColor.green, cloudColor.blue, cloudColor.alpha];
		cloudShader.uCloudIntensity.value = [cloudIntensity];
		cloudShader.uCloudScale.value = [cloudScale];

		super.draw();
	}
}

class CloudShader extends FlxFixedShader
{
	@:glFragmentSource('#pragma header
	
	uniform vec4 uCloudColor = vec4(1.0, 1.0, 1.0, 1.0);
	uniform float uCloudIntensity = 1.0;
	uniform float uCloudScale = 1.0;
	
	void main() 
	{
		vec2 uv = openfl_TextureCoordv * uCloudScale;
		vec2 noise = vec2(sin(uv.x * 10.0 + uv.y * 5.0), sin(uv.y * 10.0 + uv.x * 5.0));
		float cloud = noise.x * noise.y;
		cloud = cloud * cloud * cloud;
	
		vec4 finalColor = vec4(uCloudColor.rgb * cloud * uCloudIntensity, uCloudColor.a * cloud);
	
		gl_FragColor = finalColor;
	}
	')
	public function new()
	{
		super();
	}
}
