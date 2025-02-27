package;

typedef CharacterConfig =
{
	var name:String;
	var asset:String;
	var library:String;
	var iconColor:Array<Int>;
	var scale:Float;
	var antialias:Bool;
	var flipX:Bool;
	var ?caching:Bool;
	var ?additionalSprites:Array<
		{
			var id:String;
			var path:String;
		}>;
	var animations:Array<AnimData>;
	var offsets:Map<String, Array<Float>>;
	var ?camOffsets:
		{
			var x:Float;
			var y:Float;
		};
	var ?specialBehavior:String;
	var ?chromaticIntensity:Float;
	var ?position:
		{
			var x:Float;
			var y:Float;
		};
	var ?healthIcon:String;
	var ?spookyTextChance:Float;
	var ?spookyTextType:String;
	var ?cameraShakeOnSing:Bool;
}

typedef AnimData =
{
	var name:String;
	var prefix:String;
	var fps:Int;
	var loop:Bool;
	var ?indices:Array<Int>;
	var ?offsets:Array<Float>;
}
