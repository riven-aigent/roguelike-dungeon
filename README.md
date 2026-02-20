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
- **Critical hits**: 5% base chance, 1.5x damage multiplier
- Score tracking (kills, gold, floor depth)
- Permadeath with full stats on game over

### Equipment System
Find and equip items dropped by enemies or found in the dungeon:

| Equipment | Slot | Effect |
|-----------|------|--------|
| Iron Sword | Weapon | +2 ATK |
| Battle Axe | Weapon | +3 ATK, -1 DEF |
| Shadow Dagger | Weapon | +1 ATK, +10% Crit |
| Iron Shield | Armor | +2 DEF |
| Chain Mail | Armor | +3 DEF |
| Ring of Power | Accessory | +1 ATK, +1 DEF |
| Amulet of Life | Accessory | +10 Max HP |

- Swap equipment by picking up new items
- Old equipment drops on the ground when swapped

### Enemies (10 Regular + 3 Bosses)

| Enemy | Stats | Floor | Special |
|-------|-------|-------|---------|
| Slime | 3HP/1ATK/0DEF | 1+ | Basic |
| Bat | 2HP/2ATK/0DEF | 1+ | Fast but fragile |
| Skeleton | 5HP/2ATK/1DEF | 3+ | Armored |
| Spider | 4HP/2ATK/0DEF | 3+ | Web attack slows player |
| Wraith | 4HP/3ATK/0DEF | 4+ | Phases through walls |
| Orc | 8HP/3ATK/2DEF | 5+ | Tough |
| Fire Imp | 3HP/4ATK/0DEF | 6+ | Ranged fireball, 30% burn |
| Ghost | 3HP/5ATK/0DEF | 7+ | Invisible until adjacent |
| Golem | 15HP/2ATK/4DEF | 8+ | Slow (every other turn) |
| Mimic | 12HP/4ATK/2DEF | 9+ | Disguised as gold, drops loot |

### Boss Floors (Every 5th Floor)

| Boss | Stats | Special |
|------|-------|---------|
| Giant Slime (F5) | 25HP/4ATK/2DEF | Splits into 2 Slimes at 50% HP |
| Lich (F10) | 30HP/5ATK/3DEF | Summons a Skeleton every 3 turns |
| Shadow Dragon (F15+) | 50HP/6ATK/4DEF | 2 actions per turn |

Boss floors are single-room arenas. Defeat the boss to reveal stairs and claim a guaranteed Strength Potion.

### Status Effects
- **Poison**: 1 damage per turn for 5 turns (from Poison Dart traps, Spider attacks)
- **Burn**: 2 damage per turn for 3 turns (from Fire Imps, Dragon)
- **Slow**: Movement slowed for 3 turns (from Spider webs)

### Afflictions & Boons
**Afflictions** (debuffs from Dark Tomes, Tainted Gems):
- Frail: -2 Max HP | Weakness: -1 ATK | Clumsy: -1 DEF
- Heavy: Slowed every 8 turns | Decay: 1 HP loss every 15 turns
- Haunted: More ghosts spawn | Shadowed: -2 vision
- Vampiric: Heal on kill, lose HP over time | Berserker: +3 ATK, -5 HP

**Boons** (buffs from Ancient Shrines):
- Vigor: +3 Max HP | Strength: +1 ATK | Fortitude: +1 DEF
- Regeneration: Heal 1 HP every 20 turns | Luck: +10% gold, +5% crit
- Insight: +2 vision | Iron Will: Immune to affliction effects
- Phoenix: Revive once on death with 25% HP

### Traps
| Trap | Effect |
|------|--------|
| Spike Trap | 3 damage (one-shot) |
| Poison Dart | 2 damage + 5 turn poison |
| Fire Vent | 4 damage + 3 turn burn |
| Teleport Trap | Random teleportation |

### Items
- **Health Potion** (red cross): Restores 8 HP
- **Strength Potion** (orange arrow): +1 ATK permanently
- **Shield Scroll** (blue square): +1 DEF permanently
- **Gold** (yellow dot): +10 gold
- **Dungeon Key**: Opens secret rooms (future)
- **Antidote**: Cures poison status

### Shop System
- **Shop Floors**: Every 3rd floor (except boss floors) contains a shop
- **Shop Tile**: Look for a special shop tile in one of the rooms - step on it to access the shop
- **Available Items**:
  - **Health Potion**: Restores 8 HP (25g)
  - **Strength Potion**: +1 ATK permanently (40g)
  - **Shield Scroll**: +1 DEF permanently (40g)
  - **Gold Bag**: Gain 20 gold (15g)
  - **Revival Amulet**: Revive with 1 HP if you die (one-time use) (100g)
  - **Teleport Scroll**: Instantly teleport to stairs (60g)
  - **Blessing Scroll**: Gain 50 XP instantly (75g)
- **Persistent Progression**: Gold carries over between runs, and special items unlock permanently as you progress

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
5. ✅ Shop system with interactive shop tiles, persistent progression
6. ✅ Equipment system, 4 new enemies, status effects, traps, critical hits
