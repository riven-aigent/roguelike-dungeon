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
- **Items & Loot** — Health Potions, Strength Potions, Shield Scrolls, and Gold scattered across each floor.
- **Fog of War** — Tiles start hidden. Explore to reveal a 6-tile radius around you. Previously seen areas stay dimmed.
- **Score System** — Earn points from kills, gold, and floor depth. Final score shown on death.
- **Minimap** — 120x120 pixel minimap showing explored areas, stairs, and your position.
- **Game Over & Restart** — Die and see your final score. Tap to try again.
- **Mobile-First** — 480x800 portrait viewport. Swipe to move on touch devices.
- **Pure Rendering** — No sprites needed. Everything drawn with `_draw()` calls.

## Controls

| Input | Action |
|-------|--------|
| WASD / Arrow Keys | Move |
| Swipe (touch) | Move |
| Walk into enemy | Attack |
| Walk over item | Auto-collect |
| Step on cyan tile | Descend to next floor |
| Any key/tap on Game Over | Restart |

## Items

| Item | Symbol | Color | Effect |
|------|--------|-------|--------|
| Health Potion | Red Cross | Red | Heals 8 HP (capped at max) |
| Strength Potion | Up Arrow | Orange | +1 ATK permanently |
| Shield Scroll | Square | Blue | +1 DEF permanently |
| Gold | Dot | Yellow | +10 score |

2-4 items spawn per floor on random floor tiles.

## Enemies

| Enemy | Shape | Color | HP | ATK | DEF | Floors |
|-------|-------|-------|----|-----|-----|--------|
| Slime | Circle | Yellow-Green | 3 | 1 | 0 | 1-3 |
| Bat | Diamond | Purple | 2 | 2 | 0 | 1-5 |
| Skeleton | Square | White | 5 | 2 | 1 | 3+ |
| Orc | Large Circle | Dark Red | 8 | 3 | 2 | 5+ |

## Fog of War

- All tiles start hidden (black)
- Moving reveals tiles within a 6-tile Euclidean radius
- Previously explored tiles appear dimmed (45% brightness)
- Enemies and items are only visible within the light radius
- Stairs remain visible once discovered, even in fog
- Each new floor starts with fresh fog

## Score

Score = (Kills x 10) + Gold Collected + (Floor x 5)

Shown live in the HUD and as final score on death.

## Color Key

| Color | Meaning |
|-------|---------|
| 🟤 Dark Brown | Wall |
| ⬛ Dark Gray | Floor |
| 🟦 Cyan | Stairs Down |
| 🟢 Green Circle | You (flashes red when hit) |
| 🔴 Red Cross | Health Potion |
| 🟠 Orange Arrow | Strength Potion |
| 🔵 Blue Square | Shield Scroll |
| 🟡 Yellow Dot | Gold |

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
- [x] Items and inventory (potions, scrolls, gold)
- [x] Fog of war (6-tile reveal radius)
- [x] Score system
- [x] Minimap
- [ ] Sound effects
- [ ] More tile types and room features
- [ ] Equipment system

---

Built by [Riven ⚡](https://github.com/riven-aigent)
