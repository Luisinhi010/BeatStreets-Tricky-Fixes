import flixel.FlxG;

class Ratings
{
	public static function GenerateLetterRank(accuracy:Float):String
	{
		if (FlxG.save.data.botplay)
			return "BotPlay";
		if (accuracy == 0)
			return "N/A";

		var comboRanking:String = "";
		if (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0)
		{
			if (PlayState.goods == 0)
				comboRanking = "(MFC)"; // Marvelous (SICK) Full Combo
			else
				comboRanking = "(GFC)"; // Good Full Combo (Nothing but Goods & Sicks)
		}
		else if (PlayState.misses == 0)
			comboRanking = "(FC)"; // Regular FC
		else if (PlayState.misses < 10)
			comboRanking = "(SDCB)"; // Single Digit Combo Breaks
		else
			comboRanking = "(Clear)";

		// WIFE Conditions
		if (accuracy >= 99.9935)
			return comboRanking + " AAAAA";
		if (accuracy >= 99.980)
			return comboRanking + " AAAA:";
		if (accuracy >= 99.970)
			return comboRanking + " AAAA.";
		if (accuracy >= 99.955)
			return comboRanking + " AAAA";
		if (accuracy >= 99.90)
			return comboRanking + " AAA:";
		if (accuracy >= 99.80)
			return comboRanking + " AAA.";
		if (accuracy >= 99.70)
			return comboRanking + " AAA";
		if (accuracy >= 99)
			return comboRanking + " AA:";
		if (accuracy >= 96.50)
			return comboRanking + " AA.";
		if (accuracy >= 93)
			return comboRanking + " AA";
		if (accuracy >= 90)
			return comboRanking + " A:";
		if (accuracy >= 85)
			return comboRanking + " A.";
		if (accuracy >= 80)
			return comboRanking + " A";
		if (accuracy >= 70)
			return comboRanking + " B";
		if (accuracy >= 60)
			return comboRanking + " C";
		return comboRanking + " D";
	}

	public static function CalculateRating(noteDiff:Float, ?customSafeZone:Float):String
	{
		var timeScale = customSafeZone != null ? customSafeZone / 166 : Conductor.timeScale;

		if (Math.abs(noteDiff) > 166 * timeScale)
			return "miss";
		if (Math.abs(noteDiff) > 135 * timeScale)
			return "shit";
		if (Math.abs(noteDiff) > 90 * timeScale)
			return "bad";
		if (Math.abs(noteDiff) > 45 * timeScale)
			return "good";
		return "sick";
	}

	public static function CalculateRanking(score:Int, accuracy:Float):String
	{
		var result:String = "";

		if (!FlxG.save.data.botplay)
		{
			// Score display
			result += "Score:";
			result += score;

			// Accuracy
			var accuracyDisplay:String = FlxG.save.data.botplay ? "N/A" : CoolUtil.truncateFloat(accuracy, 2) + " %";
			result += " | Accuracy:" + accuracyDisplay;

			// Letter Rank
			var letterRank:String = GenerateLetterRank(accuracy);
			result += " | " + letterRank;

			result += '\nMisses: ${PlayState.misses} | Combo Breaks: ${PlayState.comboBreaks}';
		}

		return result;
	}
}
