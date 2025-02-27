package;

typedef NoteConfig =
{
	var offsets:
		{
			var x:Float;
			var y:Float;
			var burning:Float;
			var halo:Float;
		};
	var dimensions:
		{
			var width:Float;
			var scale:Float;
			var burningScale:Float;
		};
	var animations:
		{
			var scrollSuffixes:Array<String>;
			var holdSuffixes:Array<String>;
			var directions:Array<String>;
		};
	var paths:
		{
			var defaut:
				{
					var normal:String;
					var hard:String;
				};
			var burning:
				{
					var normal:String;
					var halo:String;
				};
		};
	var timing:
		{
			var safeZoneOffset:
				{
					var normal:Float;
					var burning:Float;
					var halo:Float;
				};
		};
	var colors:
		{
			var notes:Array<Array<Int>>;
		};
	var sustain:
		{
			var alpha:Float;
			var scoreMultiplier:Float;
		};
}

typedef ChartConfig =
{
	var gridSize:Int;
	var colors:
		{
			var highlight:
				{
					var add:String;
					var delete:String;
					var select:String;
					var copy:String;
				};
			var grid:String;
			var bg:String;
			var ui:
				{
					var bg:String;
					var text:String;
				};
		};
	var shortcuts:
		{
			var save:String;
			var undo:String;
			var redo:String;
			var copy:String;
			var paste:String;
			var delete:String;
			var selectAll:String;
			var duplicate:String;
			var play:String;
			var reset:String;
			var nudge:String;
			var nudgeLeft:String;
			var nudgeRight:String;
			var nudgeUp:String;
			var nudgeDown:String;
		};
	var shortcutLabels:
		{
			var save:String;
			var undo:String;
			var redo:String;
			var copy:String;
			var paste:String;
			var delete:String;
			var selectAll:String;
			var duplicate:String;
			var play:String;
			var reset:String;
			var nudge:String;
		};
	var autoSave:
		{
			var enabled:Bool;
			var interval:Int;
		};
	var defaultSong:
		{
			var bpm:Int;
			var speed:Float;
			var needsVoices:Bool;
		};
	var ui:
		{
			var fontSize:Int;
			var padding:Int;
			var boxWidth:Int;
		};
}

typedef DefaultConfig =
{
	var gameplay:
		{
			var downscroll:Bool;
			var accuracyDisplay:Bool;
			var offset:Int;
			var fps:Bool;
			var fpsCap:Int;
			var scrollSpeed:Float;
			var frames:Int;
			var accuracyMod:Int;
			var ghost:Bool;
			var flashing:Bool;
			var botplay:Bool;
		};
	var progress:
		{
			var beatenHard:Bool;
			var beatEx:Bool;
			var lowend:Bool;
			var warned:Bool;
		};
	var hitPosition:
		{
			var x:Int;
			var y:Int;
			var changed:Bool;
		};
	var performance:
		{
			var fpsCap:
				{
					var min:Int;
					var max:Int;
					var defaut:Int;
				};
		};
}

typedef FrameConfig =
{
	var frames:Map<String, String>; // id -> path
	var settings:
		{
			var persist:Bool;
			var destroyOnNoUse:Bool;
		};
}

typedef UIConfig = {
    var colors:{
        var background:String;
        var panel:String;
        var sidePanel:String;
        var text:String;
        var highlight:String;
        var error:String;
        var success:String;
        var warning:String;
        var button:{
            var normal:String;
            var hover:String;
            var pressed:String;
        };
    };
    var fonts:{
        var defaut:{
            var size:Int;
            var color:String;
        };
        var title:{
            var size:Int;
            var color:String;
        };
        var tooltip:{
            var size:Int;
            var color:String;
        };
    };
    var layout:{
        var padding:Int;
        var spacing:Int;
        var buttonWidth:Int;
        var buttonHeight:Int;
        var panelWidth:Int;
        var sidebarWidth:Int;
    };
    var animation:{
        var duration:Float;
        var ease:String;
        var buttonScale:Float;
        var fadeSpeed:Float;
    };
    var effects:{
        var tooltipPulse:Bool;
        var buttonHover:Bool;
        var transitions:Bool;
        var shake:{
            var intensity:Float;
            var duration:Float;
        };
    };
}
