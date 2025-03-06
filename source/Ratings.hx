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
		if (customSafeZone == null)
			customSafeZone = Conductor.safeZoneOffset;

		// Ensure timeScale isn't zero or negative to avoid division by zero
		var timeScale = (customSafeZone != null && customSafeZone > 0) ? customSafeZone / 166 : Conductor.timeScale > 0 ? Conductor.timeScale : 1;

		// Ensure noteDiff is positive for comparisons
		var absDiff:Float = Math.abs(noteDiff);

		// Safe thresholds
		var shitThreshold:Float = 166 * timeScale;
		var badThreshold:Float = 135 * timeScale;
		var goodThreshold:Float = 90 * timeScale;
		var sickThreshold:Float = 45 * timeScale;

		if (absDiff > shitThreshold)
			return "miss";
		if (absDiff > badThreshold)
			return "shit";
		if (absDiff > goodThreshold)
			return "bad";
		if (absDiff > sickThreshold)
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

			if (PlayState.misses > 0 || PlayState.comboBreaks > 0)
				result += '\nMisses: ${PlayState.misses} | Combo Breaks: ${PlayState.comboBreaks}';
		}

		return result;
	}
}
