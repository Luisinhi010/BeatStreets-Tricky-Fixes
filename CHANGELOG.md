# Changelog

This file documents all notable changes.

## [Madness Makeover] → [Madness Makeover Part2]
### **Added**
- Health drain mechanics
- Old Madness now have Ingame Events
- Expurgation have more events, And the background sprites uses Normal Maping

### **Changed**
- Characters with multiple sprites (e.g., *TrickyHell*) now use Flixel's `addAtlas()` function for better readability(and maybe optmizations improviments).

## [Vs. Tricky] → [Madness Makeover]

Only significant changes are listed here.

---

### **Added**
- Songs are now categorized based on their difficulty, focusing on:
  - **Beatstreets** (hard)
  - **Old Beatstreets** (old)
  - **Upside** (upside)
- Shaders
- Camera filters
- In-game events
- In-game animations
- Dynamic death animation for different songs

---

### **Changed**
- **Caching system**: Now loads together with the game intro.
- **Charting handling** custom notes improvements.
- Some texts are now soft-coded.
- General code improvements.
- Updated the following to their latest versions:
  - Haxe
  - Lime
  - OpenFL
  - Flixel

---

### **Fixed**
- Addressed issues present in the release version of *Vs. Tricky* that were missing in the GitHub version.
