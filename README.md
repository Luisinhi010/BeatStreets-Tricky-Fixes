# Vs. Tricky Madness Makeover

![Tricky Madness Makeover Logo](https://github.com/Luisinhi010/BeatStreets-Tricky-Fixes/blob/madness-makeover/assets/clown/images/menu/Mainlogo.webp)

This is a mod for the game [Friday Night Funkin'](https://ninja-muffin24.itch.io/funkin), inspired by other popular mods, such as:  
- [Vs. Tricky](https://gamebanana.com/mods/44334)  
- [Beaststreets Remixes](https://gamebanana.com/mods/43854)  
- [BeatStreets Vs. Tricky](https://gamebanana.com/mods/43994)  
- [Upside Remixes](https://gamebanana.com/mods/44226)  
- [Upside Vs. Tricky](https://gamebanana.com/mods/43105)  

---

## **Credits**
Special thanks to:  
- [The Funkin' Crew Inc](https://github.com/FunkinCrew)  
- [Banbuds](https://x.com/Banbuds)  
- [Rozebud](https://x.com/help_me_thebig1)  
- [KadeDev](https://github.com/kade-dev)  
- [Cval](https://x.com/cval_brown)  
- [YingYang48](https://x.com/YingWasHere)  
- [JADS](https://x.com/Aw3somejds)  
- [Moro](https://www.youtube.com/@moro_production)  
- [TomFulp](https://tomfulp.newgrounds.com)  
- [Krinkles](https://krinkles.newgrounds.com)  
- [Tsuranar](https://x.com/Tsuranar)  
- [Spooky_Pump](https://gamebanana.com/members/178262)  
- [WhippyocrY](https://gamebanana.com/members/171624)  
- [Wdbittle](https://gamebanana.com/members/1793541)  

---

## ⭐ Latest Updates

### Version 2.0
- **New Scripting System**: Advanced HScript support for characters and states
- **Enhanced Character System**: Improved character loading and animation handling
- **Configuration System**: New JSON-based config system for easy customization
- **WebP Support**: Optimized image loading with WebP format
- **Memory Optimization**: Better resource management and caching

## 🎮 Features

### Gameplay
- Custom chart system with multiple difficulty modes
- Enhanced note mechanics with burning and halo notes
- Advanced animation system with chromatic aberration effects
- Improved scoring and accuracy system

### Technical
- Modular scripting system for custom events
- Efficient asset caching and management
- WebP image optimization support
- Configurable performance settings
- Debug mode for development

### Graphics
- HD character sprites and animations
- Special visual effects and shaders
- Optimized image loading
- Customizable UI elements

## 🛠️ Installation

### Prerequisites
- [Haxe 4.2.5](https://haxe.org/download/)
- [Git](https://git-scm.com/downloads)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Lime VSCode Extension](https://marketplace.visualstudio.com/items?itemName=openfl.lime-vscode-extension)

### Setup Steps
1. Install required Haxe libraries:
```bash
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hscript
haxelib install hxcpp
haxelib install hxWebP
```

2. Clone the repository:
```bash
git clone https://github.com/Luisinhi010/BeatStreets-Tricky-Fixes.git
cd BeatStreets-Tricky-Fixes
```

## 🔧 Building

### Development Build
```bash
lime test windows -debug
```

### Performance Build
```bash
lime test windows -release
```

### Debug Options
```bash
lime test windows -debug -Dshow_traces
```

## ⚙️ Configuration

### Main Config Files
- `noteConfig.json`: Note appearance and behavior
- `chartConfig.json`: Chart editor settings
- `defaultConfig.json`: General gameplay settings
- `frameConfig.json`: Animation frame settings

### Performance Settings
Customize in `Project.xml`:
```xml
<window fps="60" vsync="false"/>
<haxedef name="HXCPP_GC_BIG_BLOCKS"/>
<define name="WebP"/>
```

## 🔍 Troubleshooting

### Common Issues

1. Compilation Errors
   - Run `lime clean`
   - Verify all Haxe libraries are installed

2. Performance Issues
   - Enable WebP optimization in Project.xml
   - Adjust memory settings
   - Use performance build for release

3. Asset Loading Issues
   - Verify all required assets are in correct directories
   - Check library paths in Project.xml
   - Ensure proper file formats are being in use

## 🤝 Contributing

### Development Flow
1. Fork repository
2. Create feature branch
3. Implement changes
4. Add unit tests
5. Submit pull request

### Code Style
- Follow HaxeFlixel conventions
- Document new features
- Include type definitions

## 📄 License
Licensed under the same terms as Friday Night Funkin'.
See `LICENSE` for details.

## 🔗 Links
- [GameBanana Page](https://gamebanana.com/mods/...)
- [Discord Server](https://discord.gg/...)
- [Bug Reports](https://github.com/...)
