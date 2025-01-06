package;

import flixel.animation.FlxAnimationController;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';

	public var holdTimer:Float = 0;

	public var iconColor:Array<Int> = [255, 0, 0];

	public var animations:Array<FlxAnimationController> = [];

	public var exSpikes:FlxSprite;

	public var chromaticabberation:Shaders.ChromaticAberrationEffect;
	public var chromaticIntensity:Float = 0.0001;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isDebug:Bool = false)
	{
		super(x, y);

		trace('creating ' + character);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		var tex:FlxAtlasFrames;
		var upside:Bool = curCharacter.endsWith('-upside');
		if (upside)
			chromaticIntensity = 0.0002;
		else if (curCharacter.endsWith('-hell'))
			chromaticIntensity = 0.001;

		switch (curCharacter)
		{
			case 'gf' | 'gf-upside':
				// GIRLFRIEND CODE
				tex = Paths.getSparrowAtlas('GF_assets' + (upside ? '-upside' : ''), 'shared');
				frames = tex;
				animation.addByPrefix('cheer', 'GF Cheer', 24, false);
				animation.addByPrefix('singLEFT', 'GF left note', 24, false);
				animation.addByPrefix('singRIGHT', 'GF Right Note', 24, false);
				animation.addByPrefix('singUP', 'GF Up Note', 24, false);
				animation.addByPrefix('singDOWN', 'GF Down Note', 24, false);
				animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByIndices('hairBlow', "GF Dancing Beat Hair blowing", [0, 1, 2, 3], "", 24);
				animation.addByIndices('hairFall', "GF Dancing Beat Hair Landing", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], "", 24, false);
				animation.addByPrefix('scared', 'GF FEAR', 24);

				addOffset('cheer');
				addOffset('sad', -2, -2);
				addOffset('danceLeft', 0, -9);
				addOffset('danceRight', 0, -9);

				addOffset("singUP", 0, 4);
				addOffset("singRIGHT", 0, -20);
				addOffset("singLEFT", 0, -19);
				addOffset("singDOWN", 0, -20);
				addOffset('hairBlow', 45, -8);
				addOffset('hairFall', 0, -9);

				addOffset('scared', -2, -17);

				playAnim('danceRight');
			case 'gf-hell':
				tex = Paths.getSparrowAtlas('hellclwn/GF/gf_phase_3', 'clown');
				frames = tex;
				animation.addByPrefix('cheer', 'GF Cheer', 24, false);
				animation.addByIndices('sad', 'gf sad', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], "", 24, false);
				animation.addByIndices('danceLeft', 'GF Dancing Beat', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				animation.addByIndices('danceRight', 'GF Dancing Beat', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				animation.addByPrefix('scared', 'GF FEAR', 24);

				addOffset('cheer');
				addOffset('sad', -2, -2);
				addOffset('danceLeft', 0, -9);
				addOffset('danceRight', 0, -9);

				addOffset('scared', -2, -17);

				playAnim('danceRight');

			case 'gf-tied':
				tex = Paths.getSparrowAtlas('fourth/EX Tricky GF', 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'GF Ex Tricky', 24);

				addOffset('idle', 0);

				playAnim('idle');

			case 'Tricky':
				iconColor = [24, 62, 95];
				tex = Paths.getSparrowAtlas('Tricky', 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'Idle', 24);
				animation.addByPrefix('singUP', 'Sing Up', 24);
				animation.addByPrefix('singRIGHT', 'Sing Right', 24);
				animation.addByPrefix('singDOWN', 'Sing Down', 24);
				animation.addByPrefix('singLEFT', 'Sing Left', 24);

				addOffset("idle", 0, -75);
				addOffset("singUP", 82, -74);
				addOffset("singRIGHT", -3, -176);
				addOffset("singLEFT", 261, -72);
				addOffset("singDOWN", 30, -103);

				playAnim('idle');

			case 'Tricky-old' | 'Tricky-upside':
				iconColor = upside ? [24, 84, 95] : [64, 24, 95];
				tex = Paths.getSparrowAtlas('Tricky' + (upside ? '-upside' : '-old'), 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'Idle', 24);
				animation.addByPrefix('singUP', 'Sing Up', 24);
				animation.addByPrefix('singRIGHT', 'Sing Right', 24);
				animation.addByPrefix('singDOWN', 'Sing Down', 24);
				animation.addByPrefix('singLEFT', 'Sing Left', 24);

				addOffset("idle", 0, -75);
				addOffset("singUP", 93, -76);
				addOffset("singRIGHT", 16, -176);
				addOffset("singLEFT", 103, -72);
				addOffset("singDOWN", 6, -84);

				playAnim('idle');

			case 'TrickyH':
				iconColor = [102, 0, 102];
				tex = CachedFrames.fromSparrow('idle', 'hellclwn/Tricky/Idle');
				tex.addAtlas(CachedFrames.fromSparrow('left', 'hellclwn/Tricky/Left'));
				tex.addAtlas(CachedFrames.fromSparrow('down', 'hellclwn/Tricky/Down'));
				tex.addAtlas(CachedFrames.fromSparrow('up', 'hellclwn/Tricky/Up'));
				tex.addAtlas(CachedFrames.fromSparrow('right', 'hellclwn/Tricky/right'));
				frames = tex;

				// graphic.persist = true;
				// graphic.destroyOnNoUse = false;

				animation.addByPrefix('idle', 'Phase 3 Tricky Idle', 24);
				animation.addByPrefix('singLEFT', 'Proper Left', 24);
				animation.addByPrefix('singDOWN', 'Proper Down', 24);
				animation.addByPrefix('singUP', 'Proper Up', 24);
				animation.addByPrefix('singRIGHT', 'Proper Right', 24);

				trace('poggers');

				addOffset("idle", 550, 220);
				addOffset("singLEFT", 765, 245);
				addOffset("singDOWN", 735, -310);
				addOffset("singUP", 1015, -220);
				addOffset("singRIGHT", 675, -110);
				playAnim('idle');
			case 'TrickyMask':
				iconColor = [24, 62, 95];
				tex = Paths.getSparrowAtlas('TrickyMask', 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'Idle', 24);
				animation.addByPrefix('singUP', 'Sing Up', 24);
				animation.addByPrefix('singRIGHT', 'Sing Right', 24);
				animation.addByPrefix('singDOWN', 'Sing Down', 24);
				animation.addByPrefix('singLEFT', 'Sing Left', 24);

				addOffset("idle", 0, -117);
				addOffset("singUP", 102, -87);
				addOffset("singRIGHT", 51, -173);
				addOffset("singLEFT", 208, -80);
				addOffset("singDOWN", 12, -144);

				dance();

			case 'TrickyMask-old' | 'TrickyMask-upside':
				iconColor = upside ? [24, 84, 95] : [64, 24, 95];
				tex = Paths.getSparrowAtlas('TrickyMask' + (upside ? '-upside' : '-old'), 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'Idle', 24);
				animation.addByPrefix('singUP', 'Sing Up', 24);
				animation.addByPrefix('singRIGHT', 'Sing Right', 24);
				animation.addByPrefix('singDOWN', 'Sing Down', 24);
				animation.addByPrefix('singLEFT', 'Sing Left', 24);

				addOffset("idle", 0, -117);
				addOffset("singUP", 93, -100);
				addOffset("singRIGHT", 16, -164);
				addOffset("singLEFT", 194, -95);
				addOffset("singDOWN", 32, -168);

				dance();

			case 'bf-hell':
				iconColor = [171, 22, 74];
				tex = Paths.getSparrowAtlas('hellclwn/BF/BF_3rd_phase', 'clown');
				frames = tex;
				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);

				animation.addByPrefix('scared', 'BF idle shaking', 24);

				addOffset('idle', -5);
				addOffset("singUP", -29, 27);
				addOffset("singRIGHT", -38, -7);
				addOffset("singLEFT", 12, -6);
				addOffset("singDOWN", -10, -50);
				addOffset("singUPmiss", -29, 27);
				addOffset("singRIGHTmiss", -30, 21);
				addOffset("singLEFTmiss", 12, 24);
				addOffset("singDOWNmiss", -11, -19);
				addOffset('scared', -4);

				dance();

				flipX = true;

			case 'signDeath':
				frames = Paths.getSparrowAtlas('signDeath', 'clown');
				animation.addByPrefix('firstDeath', 'BF dies', 24, false);
				animation.addByPrefix('deathLoop', 'BF Dead Loop', 24, false);
				animation.addByPrefix('deathConfirm', 'BF Dead confirm', 24, false);

				playAnim('firstDeath');

				addOffset('firstDeath', 263);
				addOffset('deathLoop', 1);
				addOffset('deathConfirm', 0, 47);

				animation.pause();

				updateHitbox();
				antialiasing = !FlxG.save.data.lowend;
				flipX = true;

			case 'exTricky':
				iconColor = [0, 228, 255];
				frames = Paths.getSparrowAtlas('fourth/EXTRICKY', 'clown');
				exSpikes = new FlxSprite(x - 350, y - 170);
				exSpikes.frames = Paths.getSparrowAtlas('fourth/FloorSpikes', 'clown');
				exSpikes.visible = false;

				exSpikes.animation.addByPrefix('spike', 'Floor Spikes', 24, false);

				animation.addByPrefix('idle', 'Idle', 24);
				animation.addByPrefix('singUP', 'Sing Up', 24);
				animation.addByPrefix('singLEFT', 'Sing Left', 24);
				animation.addByPrefix('singRIGHT', 'Sing Right', 24);
				animation.addByPrefix('singDOWN', 'Sing Down', 24);
				animation.addByPrefix('Hank', 'Hank', 24, true);

				addOffset('idle');
				addOffset("Hank", -13, 0);
				addOffset("singUP", 0, 148);
				addOffset("singRIGHT", -222, -29);
				addOffset("singLEFT", 260, 91);
				addOffset("singDOWN", -100, -340);

				dance();

			default:
				iconColor = upside ? [151, 151, 151] : [171, 22, 74];
				tex = Paths.getSparrowAtlas('BOYFRIEND' + (upside ? '-upside' : ''), 'shared');
				frames = tex;
				animation.addByPrefix('idle', 'BF idle dance', 24, false);
				animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
				animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
				animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
				animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
				animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
				animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
				animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
				animation.addByPrefix('hey', 'BF HEY', 24, false);

				animation.addByPrefix('firstDeath', "BF dies", 24, false);
				animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
				animation.addByPrefix('deathConfirm', "BF Dead confirm", 24, false);

				animation.addByPrefix('scared', 'BF idle shaking', 24);

				addOffset('idle', -5);
				addOffset('scared', -4);
				addOffset('firstDeath', 37, 11);
				addOffset('deathLoop', 37, 5);
				addOffset('deathConfirm', 37, 69);
				if (upside)
				{
					addOffset("singUP", -29, 27);
					addOffset("singRIGHT", -38, -7);
					addOffset("singLEFT", 12, -6);
					addOffset("singDOWN", -10, -50);
					addOffset("singUPmiss", -29, 27);
					addOffset("singRIGHTmiss", -30, 21);
					addOffset("singLEFTmiss", 12, 24);
					addOffset("singDOWNmiss", -11, -19);
					addOffset("hey", 7, 4);
				}
				else
				{
					addOffset("singUP", -48, 11);
					addOffset("singRIGHT", -77, -7);
					addOffset("singLEFT", 1, -11);
					addOffset("singDOWN", -10, -50);
					addOffset("singUPmiss", -46, 9);
					addOffset("singRIGHTmiss", -29, 21);
					addOffset("singLEFTmiss", 6, 15);
					addOffset("singDOWNmiss", -9, -27);
					addOffset("hey", -3, -3);
				}

				dance();

				flipX = true;
		}

		antialiasing = !FlxG.save.data.lowend;

		if (isPlayer)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf') && !curCharacter.toLowerCase().contains('death'))
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}

		if (!FlxG.save.data.lowend)
			shader = (chromaticabberation = new Shaders.ChromaticAberrationEffect(chromaticIntensity)).shader;
	}

	override function update(elapsed:Float)
		{
			var curAnim = animation.curAnim;
			var holdDuration = Conductor.stepCrochet * 4 * 0.001;
		
			if (!isPlayer && curAnim != null)
			{
				if (curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
		
		
				if (holdTimer >= holdDuration)
				{
					dance();
					holdTimer = 0;
				}
			}
		
			super.update(elapsed);
		}

	private var danced:Bool = false;

	public function dance(force:Bool = false)
	{
		if (!debugMode)
		{
			switch (curCharacter)
			{
				case 'gf' | 'gf-upside' | 'gf-hell':
					danced = !danced;

					if (danced)
						playAnim('danceRight', force);
					else
						playAnim('danceLeft', force);
				default:
					playAnim('idle', force);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		if (curCharacter == 'exTricky')
		{
			if (AnimName == 'singUP')
				{
					exSpikes.visible = true;
					if (exSpikes.animation.finished)
						exSpikes.animation.play('spike');
					else if (exSpikes.animation.frameIndex >= 3)
						exSpikes.animation.pause();
				}
			else if (!exSpikes.animation.finished)
			{
				exSpikes.animation.resume();
				exSpikes.animation.finishCallback = function(pog:String)
				{
					exSpikes.visible = false;
					exSpikes.animation.finishCallback = null;
				}
			}
		}

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;
			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];
}
