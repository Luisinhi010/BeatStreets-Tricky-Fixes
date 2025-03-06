package states;

import flixel.FlxG;
import Character;
import PlayState;

using StringTools;

class CharacterState
{
	public static function resetCharacters(bf:Character, opp:Character, gf:Character)
	{
		if (bf != null)
		{
			bf.dance();
			bf.animation.finishCallback = null;
		}
		if (opp != null)
		{
			opp.dance();
			opp.animation.finishCallback = null;
		}
		if (gf != null)
		{
			gf.dance();
			gf.animation.finishCallback = null;
		}
	}

	public static function updateCharacterPositions(state:PlayState)
	{
		if (state.opp.charData != null && state.opp.charData.position != null)
		{
			state.opp.x += state.opp.charData.position.x;
			state.opp.y += state.opp.charData.position.y;
		}

		if (state.gf.charData != null && state.gf.charData.position != null)
		{
			state.gf.x += state.gf.charData.position.x;
			state.gf.y += state.gf.charData.position.y;
		}

		if (state.bf.charData != null && state.bf.charData.position != null)
		{
			state.bf.x -= state.bf.charData.position.x;
			state.bf.y += state.bf.charData.position.y;
		}
	}

	public static function updateAnimations(state:PlayState)
	{
		var beatPassed = state.curBeat % 2 == 0;
		if (beatPassed)
		{
			if (!state.bf.animation.curAnim.name.startsWith("sing"))
				state.bf.dance();

			if (!state.opp.animation.curAnim.name.startsWith("sing"))
				state.opp.dance();

			state.gf.dance();
		}
	}

	public static function handleSing(char:Character, noteData:Int, isSustainNote:Bool = false)
	{
		var directions = ["LEFT", "DOWN", "UP", "RIGHT"];
		var anim = "sing" + directions[noteData];

		if (isSustainNote && char.animation.curAnim.name == "idle")
			char.playAnim(anim);
		else if (!isSustainNote)
			char.playAnim(anim, true);
	}

	public static function handleMissAnimation(char:Character, direction:Int)
	{
		var directions = ["LEFT", "DOWN", "UP", "RIGHT"];

		if (direction < 0 || direction >= directions.length)
			return;

		var anim = "sing" + directions[direction] + "miss";
		char.playAnim(anim, true);
	}
}
