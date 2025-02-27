package scripting;

typedef ScriptEvent = {
    var name:String;
    var callback:Dynamic;
    var once:Bool;
}

class EventManager {
    private var events:Map<String, Array<ScriptEvent>> = new Map();

    public function new() {}

    public function on(event:String, callback:Dynamic) {
        if (!events.exists(event))
            events.set(event, []);
            
        events.get(event).push({
            name: event,
            callback: callback,
            once: false
        });
    }

    public function once(event:String, callback:Dynamic) {
        if (!events.exists(event))
            events.set(event, []);
            
        events.get(event).push({
            name: event,
            callback: callback, 
            once: true
        });
    }

    public function emit(event:String, ?args:Array<Dynamic>) {
        if (!events.exists(event)) return;

        var eventList = events.get(event);
        var i = eventList.length;
        while (i-- > 0) {
            var e = eventList[i];
            e.callback(args);
            if (e.once)
                eventList.remove(e);
        }
    }

    public function removeEvent(event:String, ?callback:Dynamic) {
        if (!events.exists(event)) return;
        
        if (callback == null)
            events.remove(event);
        else {
            var eventList = events.get(event);
            var i = eventList.length;
            while (i-- > 0) {
                if (eventList[i].callback == callback)
                    eventList.remove(eventList[i]);
            }
        }
    }

    public function clear() {
        events.clear();
    }
}
