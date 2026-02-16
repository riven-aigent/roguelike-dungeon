# Depths of Ruin ⚔️

A turn-based roguelike dungeon crawler built with Godot 4.6. Infinite procedurally generated floors, permadeath, and pure `_draw()` rendering (no sprites).

**Play now:** [https://riven-aigent.github.io/roguelike-dungeon/](https://riven-aigent.github.io/roguelike-dungeon/)

## Features

### Core
- BSP-based procedural dungeon generation
- Grid-based movement (WASD + arrow keys + touch/swipe)
- Infinite floor descent via stairs
- Fog of war with 6-tile vision radius
- Minimap with enemy tracking
- Scrolling message log (last 5 messages with fade)

### Combat & Progression
- Turn-based bump combat with ATK/DEF stats
- **XP & Leveling system**: Earn XP from kills, level up for +5 HP (full heal) and +1 ATK
- Score tracking (kills, gold, floor depth)
- Permadeath with full stats on game over

### Enemies (7 Regular + 3 Bosses)

| Enemy | Stats | Floor | Special |
|-------|-------|-------|---------|
| Slime | 3HP/1ATK/0DEF | 1+ | Basic |
| Bat | 2HP/2ATK/0DEF | 1+ | Fast but fragile |
| Skeleton | 5HP/2ATK/1DEF | 3+ | Armored |
| Wraith | 4HP/3ATK/0DEF | 4+ | Phases through walls |
| Orc | 8HP/3ATK/2DEF | 5+ | Tough |
| Fire Imp | 3HP/4ATK/0DEF | 6+ | Ranged fireball (2-3 tiles) |
| Golem | 15HP/2ATK/4DEF | 8+ | Slow (moves every other turn) |

### Boss Floors (Every 5th Floor)

| Boss | Stats | Special |
|------|-------|---------|
| Giant Slime (F5) | 25HP/4ATK/2DEF | Splits into 2 Slimes at 50% HP |
| Lich (F10) | 30HP/5ATK/3DEF | Summons a Skeleton every 3 turns |
| Shadow Dragon (F15+) | 50HP/6ATK/4DEF | 2 actions per turn |

Boss floors are single-room arenas. Defeat the boss to reveal stairs and claim a guaranteed Strength Potion.

### Items
- **Health Potion** (red cross): Restores 8 HP
- **Strength Potion** (orange arrow): +1 ATK permanently
- **Shield Scroll** (blue square): +1 DEF permanently
- **Gold** (yellow dot): +10 score

## Controls
- **WASD / Arrow Keys**: Move & attack
- **Swipe**: Touch movement (mobile)
- **Any key/tap**: Restart after game over

## Tech
- Godot 4.6 (GDScript)
- Pure `_draw()` rendering, zero sprites
- Automated CI/CD via GitHub Actions (Godot HTML5 export)
- Mobile-first (480x800 viewport)

## Development Phases
1. ✅ Dungeon generation, movement, stairs
2. ✅ Enemies (4 types), bump combat, AI
3. ✅ Items, fog of war, score, minimap
4. ✅ XP/leveling, 3 new enemies, boss floors, message log
