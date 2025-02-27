# BeatStreets Modding Guide

## Directory Structure

```
mods/
├── MyModName/
│   ├── mod.json      # Mod metadata
│   ├── songs/        # Custom songs
│   │   └── mysong/
│   │       ├── Inst.ogg
│   │       ├── Voices.ogg
│   │       └── script.hx
│   ├── images/       # Custom images/sprites
│   ├── sounds/       # Custom sound effects
│   ├── data/         # Custom data files
│   │   ├── characters/   # Character definitions
│   │   └── stages/       # Stage definitions
│   └── scripts/      # Custom scripts
│       ├── states/   # State scripts
│       └── events/   # Custom events
```

## Asset Types
Your mod can override or add:

- Songs
- Characters
- Stages
- Images/Sprites
- Sound Effects
- Scripts
- States
- Events

## Examples
- Custom Song
- Custom Character
- Custom Script

## Loading Order
- Mod assets are checked first
- If not found, falls back to base game assets
- Mods are loaded by loadPriority (highest first)
- Dependencies are resolved automatically

## Tips
- Use unique names for custom content
- Test mods thoroughly
- Document your mod's features

## API Reference
- ModManager
- Paths

## Testing Mods
1. Enable mod loading in settings
2. Place mod in mods folder
3. Check logs for loading status

## Troubleshooting
Common issues:

### Mod not loading
- Check mod.json format
- Verify file paths
- Check dependencies

### Assets not found
- Verify folder structure
- Check file names
- Enable mod debugging

### Scripts errors
- Check syntax
- Verify API usage
- Enable script debugging