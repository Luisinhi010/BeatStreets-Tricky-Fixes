function onCreate() {
    trace("MainMenuState script onCreate() chamado!");
}

function onUpdate(elapsed:Float) {
    // Uncomment para ver se está sendo chamado
    trace("MainMenuState onUpdate: " + elapsed);
}

function onBeatHit(curBeat:Int) {
    trace("MainMenuState onBeatHit: " + curBeat);
}

function onStepHit(curStep:Int) {
    trace("MainMenuState onStepHit: " + curStep);
}