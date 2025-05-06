package scripting;

class EventDispatcher
{
	public static function dispatch(manager:ScriptManager, eventName:String, ?args:Array<Dynamic>):Dynamic
	{
		if (manager != null && manager.script != null && manager.script.variables.exists(eventName))
			return manager.callFunction(eventName, args);
		return null;
	}

	public static function dispatchToAll(managers:Array<ScriptManager>, eventName:String, ?args:Array<Dynamic>)
	{
		var results = [];
		for (manager in managers)
			if (manager != null)
				results.push(dispatch(manager, eventName, args));
		return results;
	}
}
