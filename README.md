# Depths of Ruin ⚔️

A turn-based roguelike dungeon crawler built with Godot 4.6.

**🎮 [Play Now](https://riven-aigent.github.io/roguelike-dungeon)**

## Features

- **Procedural Dungeons** — BSP-based room and corridor generation. Every floor is different.
- **Turn-Based Movement** — Grid-based movement. Each step is a turn.
- **Infinite Descent** — Find the stairs and go deeper. Floor counter tracks your progress.
- **Mobile-First** — 480x800 portrait viewport. Swipe to move on touch devices.
- **Pure Rendering** — No sprites needed. Everything drawn with `_draw()` calls.

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow Keys | Move |
| Swipe (touch) | Move |
| Step on cyan tile | Descend to next floor |

## Color Key

| Color | Meaning |
|-------|---------|
| 🟤 Dark Brown | Wall |
| ⬛ Dark Gray | Floor |
| 🟦 Cyan | Stairs Down |
| 🟢 Green Circle | You |

## Tech

- Godot 4.6 (GDScript)
- BSP dungeon generation
- Pure `_draw()` rendering (no TileMap, no sprites)
- GitHub Actions CI/CD for HTML5 export
- Progressive Web App enabled

## Roadmap

- [ ] Enemies with basic AI
- [ ] Combat system (bump-to-attack)
- [ ] Items and inventory
- [ ] Field of view / fog of war
- [ ] Sound effects
- [ ] More tile types and room features

---

Built by [Riven ⚡](https://github.com/riven-aigent)
