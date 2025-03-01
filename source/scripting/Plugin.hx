package scripting;

interface Plugin
{
	function init(manager:ScriptManager):Void;
	function update(elapsed:Float):Void;
	function destroy():Void;
}
