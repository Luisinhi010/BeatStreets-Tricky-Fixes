package;

import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BlendMode;

class BlendModeState extends FlxState {
    var currentBlendMode:Int = 0;
    var blendModes:Array<BlendMode> = [
        NORMAL, ADD, MULTIPLY, SCREEN, OVERLAY, DARKEN, LIGHTEN, DIFFERENCE, SUBTRACT, INVERT
    ];
    var blendText:FlxText;
    var notes:FlxTypedGroup<Note>;
    var hardNotes:FlxTypedGroup<Note>;
    var isBurning:Bool = false;

    override public function create():Void {
        createBackground();

        var infoText = new FlxText(10, 10, FlxG.width,
            "LEFT/RIGHT ARROWS - Change BlendMode\nSPACE - Toggle Fire Notes\nESC - Back to Menu", 16);
        add(infoText);

        blendText = new FlxText(10, 70, FlxG.width, "", 24);
        add(blendText);

        notes = new FlxTypedGroup<Note>();
        hardNotes = new FlxTypedGroup<Note>();
        add(notes);
        add(hardNotes);

        createNotes();
        updateBlendText();

        super.create();
    }

    function createBackground():Void {
        var bg = new FlxSprite(-10, -10).loadGraphic(Paths.image('menu/freeplay/RedBG', 'clown'));
        bg.scrollFactor.set();
        bg.screenCenter();
        bg.y += 40;
        add(bg);
        
		var mist = new VolumetricCloudSprite(0, 0);
		mist.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		mist.cloudType = MIST;
		mist.setColors(0xFF545FC4, 0xFFCACAFA);
		mist.blend = ADD;
		add(mist);

        function addBackgroundElement(graphic:String, x:Float, y:Float, scale:Float):Void {
            var sprite = new FlxSprite(x, y).loadGraphic(Paths.image(graphic, 'clown'));
            sprite.setGraphicSize(Std.int(sprite.width * scale));
            add(sprite);
        }

        addBackgroundElement('menu/freeplay/hedge', -810, -335, 0.65);
        addBackgroundElement('menu/freeplay/Shadescreen', -205, -100, 0.65);
        addBackgroundElement('menu/freeplay/theBox', -225, -395, 0.65);
    }


    function createNotes():Void {
        notes.clear();
        hardNotes.clear();

        var spacing = 160 * 0.7;
        var centerX = (FlxG.width - (spacing * 3)) / 2;
        var normalY = FlxG.height * 0.3;
        var hardY = FlxG.height * 0.6;

        function addNotes(group:FlxTypedGroup<Note>, y:Float, hard:Bool = false):Void {
            for (i in 0...4) {
                var note = new Note(0, i, isBurning, null, false, hard, hard);
                note.x = centerX + (i * spacing);
                note.y = y;
                note.blend = blendModes[currentBlendMode];
                group.add(note);

                if (!isBurning) {
                    var sustainNote = new Note(0, i, false, note, true, hard, hard);
                    sustainNote.x = note.x;
                    sustainNote.y = note.y + 100;
                    sustainNote.blend = blendModes[currentBlendMode];
                    group.add(sustainNote);
                }
            }
        }

        addNotes(notes, normalY);
        addNotes(hardNotes, hardY, true);
    }

    inline function updateBlendText():Void {
        blendText.text = 'Current BlendMode: ${blendModes[currentBlendMode]}';
    }

    function updateNoteBlends():Void {
        for (note in notes.members) {
            if (note.exists && note.visible) {
                note.blend = blendModes[currentBlendMode];
            }
        }
        for (note in hardNotes.members) {
            if (note.exists && note.visible) {
                note.blend = blendModes[currentBlendMode];
            }
        }
    }


    override public function update(elapsed:Float):Void {
        if (FlxG.keys.justPressed.RIGHT) {
            currentBlendMode = (currentBlendMode + 1) % blendModes.length;
        } else if (FlxG.keys.justPressed.LEFT) {
            currentBlendMode = (currentBlendMode + blendModes.length - 1) % blendModes.length;
        }

        if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.LEFT) {
            updateNoteBlends();
            updateBlendText();
        }

        if (FlxG.keys.justPressed.SPACE) {
            isBurning = !isBurning;
            createNotes();
        }

        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.switchState(new MainMenuState());
        }

        super.update(elapsed);
    }
}
