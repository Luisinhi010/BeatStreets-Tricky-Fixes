package; // Taken from Wednesdays-Infidelity: https://github.com/lunarcleint/Wednesdays-Infidelity/blob/master/source/data/CppAPI.hx

class CppAPI
{
	#if cpp
	public static function obtainRAM():Int
	{
		return WindowsData.obtainRAM();
	}

	public static function darkMode()
	{
		WindowsData.setWindowColorMode(DARK);
	}

	public static function lightMode()
	{
		WindowsData.setWindowColorMode(LIGHT);
	}

	public static function setWindowOppacity(a:Float)
	{
		WindowsData.setWindowAlpha(a);
	}

	public static function _setWindowLayered()
	{
		WindowsData._setWindowLayered();
	}
	#else
	public static function obtainRAM():Int
	{
		return Math.floor(openfl.system.System.totalMemory / 1024 / 1024); // Convert bytes to megabytes
	}
	public static function darkMode() {}
	public static function lightMode() {}
	public static function setWindowOppacity(a:Float) {}
	public static function _setWindowLayered() {}
	#end
}
