
var exSpikes:FlxSprite;

function onCreate(char:Character) {
    exSpikes = new FlxSprite(char.x - 350, char.y - 170);
    exSpikes.frames = Paths.getSparrowAtlas('fourth/FloorSpikes', 'clown');
    exSpikes.visible = false;
    exSpikes.animation.addByPrefix('spike', 'Floor Spikes', 24, false);
}

function onCreateAfter(char:Character) {
    Game.add(exSpikes);
}

function onPlayAnim(char:Character, animName:String) {
    if (animName == 'singUP') {
        exSpikes.visible = true;
        if (exSpikes.animation.finished)
            exSpikes.animation.play('spike');
        else if (exSpikes.animation.frameIndex >= 3)
            exSpikes.animation.pause();
    }
    else if (!exSpikes.animation.finished) {
        exSpikes.animation.resume();
        exSpikes.animation.finishCallback = function(pog:String) {
            exSpikes.visible = false;
            exSpikes.animation.finishCallback = null;
        }
    }
}

function onDestroy(char:Character) {
    if (exSpikes != null) {
        exSpikes.destroy();
        exSpikes = null;
    }
}