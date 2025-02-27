package scripting;

class ScriptUtils {
    public static function getScriptPath(scriptName:String, scriptType:String):String {
        return switch(scriptType) {
            case "song": 'assets/preload/data/songs/${scriptName.toLowerCase()}/script.hx';
            case "class": 'assets/preload/data/scripts/class/${scriptName}.hx';
            case "general": 'assets/preload/data/scripts/general/${scriptName}.hx';
            default: '';
        }
    }

    public static function logScriptError(scriptName:String, error:String) {
        trace('[$scriptName] Error: $error');
    }

    public static function logScriptInfo(scriptName:String, info:String) {
        trace('[$scriptName] $info'); 
    }

    public static function formatScriptTime(ms:Float):String {
        var seconds = Math.floor(ms / 1000);
        var minutes = Math.floor(seconds / 60);
        seconds = seconds % 60;
        return '${minutes}:${seconds < 10 ? "0" : ""}${seconds}';
    }

    public static function safeCallFunction(manager:ScriptManager, functionName:String, ?args:Array<Dynamic>):Dynamic {
        try {
            return manager.callFunction(functionName, args);
        } catch(e) {
            logScriptError(manager.currentScript, 'Error calling $functionName: ${e.message}');
            return null;
        }
    }

    public static function addDefaultVariables(manager:ScriptManager, state:Dynamic) {
        // Game state
        manager.set("state", state);
        manager.set("game", PlayState.staticVar);
        
        // Utility functions
        manager.set("log", function(msg:String) logScriptInfo(manager.currentScript, msg));
        manager.set("error", function(msg:String) logScriptError(manager.currentScript, msg));
        manager.set("formatTime", formatScriptTime);
        
        // Paths
        manager.set("songPath", "assets/preload/data/songs/");
        manager.set("scriptPath", "assets/preload/data/scripts/");
    }
}
