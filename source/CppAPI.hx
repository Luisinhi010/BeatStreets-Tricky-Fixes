package;

import flixel.FlxG;
import WindowsData.PowerMode;

/**
 * High-level wrapper for native system functionality.
 * Provides a friendly API for Windows/system features.
 * Handles power management, window control and system optimization.
 */
class CppAPI
{
	/**
	 * Gets total system RAM.
	 * @return RAM in MB or -1 if failed
	 */
	public static function obtainRAM():Int
	{
		return WindowsData.obtainRAM();
	}

	/**
	 * Enables dark mode for the window.
	 * Changes window theme and title bar to dark colors.
	 */
	public static function darkMode()
	{
		WindowsData.setWindowColorMode(DARK);
	}

	/**
	 * Enables light mode for the window.
	 * Changes window theme and title bar to light colors.
	 */
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

	// Sistema de energia
	public static function getBatteryPercentage():Int
	{
		#if windows
		return WindowsData.getBatteryLife();
		#else
		return -1;
		#end
	}

	public static function isCharging():Bool
	{
		#if windows
		return WindowsData.isPluggedIn();
		#else
		return false;
		#end
	}

	public static function disableSleep()
	{
		#if windows
		WindowsData.preventSleep();
		#end
	}

	public static function enableSleep()
	{
		#if windows
		WindowsData.allowSleep();
		#end
	}

	// Monitor e janela
	public static function getScreenCount():Int
	{
		#if windows
		return WindowsData.getMonitorCount();
		#else
		return 1;
		#end
	}

	public static function getCurrentDisplaySize():{width:Int, height:Int}
	{
		#if windows
		return {
			width: WindowsData.getCurrentMonitorWidth(),
			height: WindowsData.getCurrentMonitorHeight()
		};
		#else
		return {width: 0, height: 0};
		#end
	}

	public static function moveWindow(x:Int, y:Int):Bool
	{
		#if windows
		return WindowsData.setWindowPosition(x, y);
		#else
		return false;
		#end
	}

	public static function maximizeWindow()
	{
		#if windows
		WindowsData.maximizeWindow();
		#end
	}

	public static function restoreWindow()
	{
		#if windows
		WindowsData.restoreWindow();
		#end
	}

	public static function isMaximized():Bool
	{
		#if windows
		return WindowsData.isWindowMaximized();
		#else
		return false;
		#end
	}

	// Notificações e UI
	public static function showNotification(title:String, message:String)
	{
		#if windows
		WindowsData.showMessageBox(title, message);
		#end
	}

	/**
	 * Gets current system power mode.
	 * @return PowerMode enum indicating power profile
	 */
	public static function getPowerMode():PowerMode
	{
		#if windows
		return cast WindowsData.getPowerMode();
		#else
		return UNKNOWN;
		#end
	}

	/**
	 * Optimizes game settings based on power mode.
	 * Adjusts FPS and quality settings according to:
	 * - Power saving: 30 FPS, low quality
	 * - Normal: 60 FPS, balanced
	 * - Max performance: 144 FPS, high quality
	 */
	public static function optimizeForPowerMode()
	{
		#if windows
		switch (getPowerMode())
		{
			case POWER_SAVING:
				// Reduz FPS, qualidade etc
				FlxG.drawFramerate = 30;
				FlxG.updateFramerate = 30;

			case MAX_PERFORMANCE:
				// Máxima qualidade
				FlxG.drawFramerate = 144;
				FlxG.updateFramerate = 144;

			case NORMAL:
				// Configurações padrão balanceadas
				FlxG.drawFramerate = 60;
				FlxG.updateFramerate = 60;

			case UNKNOWN:
				// Mantém configuração atual
		}
		#end
	}
}
