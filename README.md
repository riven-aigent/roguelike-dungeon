# Depths of Ruin ⚔️

A turn-based roguelike dungeon crawler built with Godot 4.6.

**🎮 [Play Now](https://riven-aigent.github.io/roguelike-dungeon)**

## Features

- **Procedural Dungeons** — BSP-based room and corridor generation. Every floor is different.
- **Turn-Based Movement** — Grid-based movement. Each step is a turn.
- **Infinite Descent** — Find the stairs and go deeper. Floor counter tracks your progress.
- **Enemies & Combat** — Bump-to-attack combat with 4 enemy types that scale by floor.
- **Enemy AI** — Enemies chase you within 5 tiles, otherwise wander randomly.
- **Player Stats** — HP, ATK, DEF. Survive as long as you can.
- **Game Over & Restart** — Die and see your score. Tap to try again.
- **Mobile-First** — 480x800 portrait viewport. Swipe to move on touch devices.
- **Pure Rendering** — No sprites needed. Everything drawn with `_draw()` calls.

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow Keys | Move |
| Swipe (touch) | Move |
| Walk into enemy | Attack |
| Step on cyan tile | Descend to next floor |
| Any key/tap on Game Over | Restart |

## Enemies

| Enemy | Shape | Color | HP | ATK | DEF | Floors |
|-------|-------|-------|----|-----|-----|--------|
| Slime | Circle | Yellow-Green | 3 | 1 | 0 | 1-3 |
| Bat | Diamond | Purple | 2 | 2 | 0 | 1-5 |
| Skeleton | Square | White | 5 | 2 | 1 | 3+ |
| Orc | Large Circle | Dark Red | 8 | 3 | 2 | 5+ |

## Color Key

| Color | Meaning |
|-------|---------|
| 🟤 Dark Brown | Wall |
| ⬛ Dark Gray | Floor |
| 🟦 Cyan | Stairs Down |
| 🟢 Green Circle | You (flashes red when hit) |

## Combat

- **Bump-to-attack**: Walk into an enemy to deal damage
- **Damage formula**: max(1, ATK - target DEF)
- **Enemy turns**: After you move, all enemies take a turn
- **Chase AI**: Enemies within 5 tiles (Manhattan distance) chase you
- **Death**: Reach 0 HP and it's game over

## Tech

- Godot 4.6 (GDScript)
- BSP dungeon generation
- Pure `_draw()` rendering (no TileMap, no sprites)
- GitHub Actions CI/CD for HTML5 export
- Progressive Web App enabled

## Roadmap

- [x] Procedural dungeon generation
- [x] Turn-based movement
- [x] Enemies with basic AI
- [x] Combat system (bump-to-attack)
- [ ] Items and inventory
- [ ] Field of view / fog of war
- [ ] Sound effects
- [ ] More tile types and room features

---

Built by [Riven ⚡](https://github.com/riven-aigent)
