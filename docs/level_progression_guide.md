## LevelProgression Documentation
## Level-Focused vs Stat-Focused Systems

# LEVEL-FOCUSED PROGRESSION SYSTEM

## Overview
A **level-focused** progression system calculates character stats dynamically based on a character's level and predefined multipliers. This is the opposite of a stat-focused system (which only modifies individual stat values without level progression).

## Formula
```
Final Stat = Base Stat + (Level - 1) × Stat Multiplier
```

### Example: Health Growth
- **Base Health at Level 1:** 100 HP
- **Health Multiplier:** 20 HP per level
- **Level 5:** 100 + (5-1)×20 = 180 HP
- **Level 10:** 100 + (10-1)×20 = 280 HP

## Why Level-Focused is Better

### 1. Predictability
Stats scale consistently with level. Players know exactly how strong a character will be at any given level.

### 2. Class-Based Balance
Classes (Mage, Warrior, Healer) get different multipliers. A Mage might have:
- **High** attack_multiplier (spell damage)
- **Low** defense_multiplier (fragile)

A Warrior might have:
- **Low** attack_multiplier (slower damage scaling)
- **High** defense_multiplier (tank role)

### 3. Simplified Leveling
No complex stat algorithms. A single "level up" increases all stats automatically using their multipliers.

### 4. Easy Difficulty Scaling
Enemies at higher levels still follow the same formula, making boss encounters consistent in difficulty.

## How to Use in This Game

### Setting Up a Character
1. **Open BattlerStats resource** (.tres file for a character)
2. **Set Base Stats (Level 1):**
   - `max_health: 100`
   - `attack: 10`
   - `defense: 5`
   - `agility: 8`

3. **Set Stat Multipliers:**
   - `health_multiplier: 20` (gains 20 HP per level)
   - `attack_multiplier: 2` (gains 2 ATK per level)
   - `defense_multiplier: 1` (gains 1 DEF per level)
   - `agility_multiplier: 1` (gains 1 AGI per level)

### In Battle
- Stats are automatically applied when a Battler enters the scene via `apply_level_progression()`
- When a character gains experience and levels up, `LevelProgression.level_up()` recalculates stats
- No need to manually update individual stats

### Character Classes Example
```gdscript
# WARRIOR CLASS (balanced tank)
max_health: 150, health_multiplier: 25
attack: 12, attack_multiplier: 3
defense: 8, defense_multiplier: 3
agility: 5, agility_multiplier: 1

# MAGE CLASS (high damage, fragile)
max_health: 70, health_multiplier: 10
attack: 18, attack_multiplier: 4
defense: 3, defense_multiplier: 0
agility: 10, agility_multiplier: 2

# HEALER CLASS (support focus)
max_health: 90, health_multiplier: 15
attack: 8, attack_multiplier: 1
defense: 5, defense_multiplier: 2
agility: 7, agility_multiplier: 1
```

## Key Functions

- **`LevelProgression.apply_level_stats()`** - Applies calculated stats to a battler
- **`LevelProgression.level_up()`** - Processes level up, recalculates stats
- **`Battler.apply_level_progression()`** - Called in _ready() to initialize stats
- **`Battler.gain_experience()`** - Add exp and check for level up

This system keeps progression clean, predictable, and balanced across all characters.
