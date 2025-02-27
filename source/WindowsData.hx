package; // Taken from Wednesdays-Infidelity: https://github.com/lunarcleint/Wednesdays-Infidelity/blob/master/source/data/WindowsData.hx

#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
    <lib name="powrprof.lib" if="windows" />
    <lib name="winmm.lib" if="windows" />
</target>
')
@:headerCode('
#include <Windows.h>
#include <cstdio>
#include <iostream>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <powrprof.h>
#include <mmsystem.h>
')
#elseif linux
@:headerCode("#include <stdio.h>")
#end
class WindowsData
{
	#if windows
	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);

		return (allocatedRAM / 1024);
	")
	#elseif linux
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

    	if(meminfo == NULL)
			return -1;

    	char line[256];
    	while(fgets(line, sizeof(line), meminfo))
    	{
        	int ram;
        	if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
        	{
            	fclose(meminfo);
            	return (ram / 1024);
        	}
    	}

    	fclose(meminfo);
    	return -1;
	')
	#end
	/**
	 * Gets the total RAM installed in the system.
	 * @return Total RAM in MB or -1 if failed
	 */
	public static function obtainRAM()
	{
		return 0;
	}

	#if windows
	@:functionCode('
        int darkMode = mode;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
            DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
        }
        UpdateWindow(window);
    ')
	@:noCompletion
	public static function _setWindowColorMode(mode:Int)
	{
	}

	/**
	 * Sets the window color mode between light/dark themes.
	 * @param mode The desired color mode
	 */ 
	public static function setWindowColorMode(mode:WindowColorMode)
	{
		var darkMode:Int = cast(mode, Int);

		if (darkMode > 1 || darkMode < 0)
		{
			trace("WindowColorMode Not Found...");

			return;
		}

		_setWindowColorMode(darkMode);
	}

	@:functionCode('
	HWND window = GetActiveWindow();
	SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
	')
	@:noCompletion
	public static function _setWindowLayered()
	{
	}

	@:functionCode('
        HWND window = GetActiveWindow();

		float a = alpha;

		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(window, 0, (255 * (a * 100)) / 100, LWA_ALPHA);

    ')
	/**
	 * Sets window transparency level.
	 * @param alpha Value from 0 to 1 for transparency
	 */
	public static function setWindowAlpha(alpha:Float)
	{
		return alpha;
	}

    @:functionCode('
        SYSTEM_POWER_STATUS powerStatus;
        if (GetSystemPowerStatus(&powerStatus)) {
            return powerStatus.BatteryLifePercent;
        }
        return -1;
    ')
	/**
	 * Gets current battery percentage.
	 * @return Battery percentage or -1 if failed
	 */
    public static function getBatteryLife():Int {
        return -1;
    }

    @:functionCode('
        SYSTEM_POWER_STATUS powerStatus;
        if (GetSystemPowerStatus(&powerStatus)) {
            return powerStatus.ACLineStatus == 1;
        }
        return false;
    ')
    public static function isPluggedIn():Bool {
        return false;
    }

    @:functionCode('
        SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);
    ')
    public static function preventSleep() {}

    @:functionCode('
        SetThreadExecutionState(ES_CONTINUOUS);
    ')
    public static function allowSleep() {}

    @:functionCode('
        return GetSystemMetrics(SM_CMONITORS);
    ')
    public static function getMonitorCount():Int {
        return 1;
    }

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
        MONITORINFO info;
        info.cbSize = sizeof(MONITORINFO);
        if (GetMonitorInfo(monitor, &info)) {
            return (info.rcMonitor.right - info.rcMonitor.left);
        }
        return 0;
    ')
    public static function getCurrentMonitorWidth():Int {
        return 0;
    }

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
        MONITORINFO info;
        info.cbSize = sizeof(MONITORINFO);
        if (GetMonitorInfo(monitor, &info)) {
            return (info.rcMonitor.bottom - info.rcMonitor.top);
        }
        return 0;
    ')
    public static function getCurrentMonitorHeight():Int {
        return 0;
    }

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        int x = screenX;
        int y = screenY;
        return SetWindowPos(hwnd, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    ')
    public static function setWindowPosition(screenX:Int, screenY:Int):Bool {
        return false;
    }

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        ShowWindow(hwnd, SW_MAXIMIZE);
    ')
    public static function maximizeWindow() {}

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        ShowWindow(hwnd, SW_RESTORE);
    ')
    public static function restoreWindow() {}

    @:functionCode('
        HWND hwnd = GetActiveWindow();
        return IsZoomed(hwnd);
    ')
    public static function isWindowMaximized():Bool {
        return false;
    }

    @:functionCode('
        int len1 = MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, NULL, 0);
        wchar_t* wTitle = new wchar_t[len1];
        MultiByteToWideChar(CP_UTF8, 0, title.c_str(), -1, wTitle, len1);
        
        int len2 = MultiByteToWideChar(CP_UTF8, 0, msg.c_str(), -1, NULL, 0);
        wchar_t* wMessage = new wchar_t[len2];
        MultiByteToWideChar(CP_UTF8, 0, msg.c_str(), -1, wMessage, len2);
        
        MessageBoxW(NULL, wMessage, wTitle, MB_OK | MB_ICONINFORMATION);
        
        delete[] wTitle;
        delete[] wMessage;
    ')
    public static function showMessageBox(title:String, msg:String) {}
    

    @:functionCode('
        SYSTEM_POWER_STATUS powerStatus;
        if (GetSystemPowerStatus(&powerStatus)) {
            switch(powerStatus.SystemStatusFlag) {
                case 0: return 0; // Normal
                case 1: return 1; // Power Saving
                case 2: return 2; // Maximum Performance
                default: return -1;
            }
        }
        return -1;
    ')
    public static function getPowerMode():Int {
        return -1;
    }
	#end
}

@:enum abstract WindowColorMode(Int)
{
	var DARK:WindowColorMode = 1;
	var LIGHT:WindowColorMode = 0;
}

@:enum abstract PowerMode(Int) {
    var NORMAL = 0;
    var POWER_SAVING = 1;
    var MAX_PERFORMANCE = 2;
    var UNKNOWN = -1;
}
