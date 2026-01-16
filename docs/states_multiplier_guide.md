# States Damage Multiplier System - Documentation

## Overview

The state system uses a damage multiplier formula to scale damage-over-time (DOT) and healing-over-time (HOT) effects based on the **target's defensive stats**. This prevents states from being overpowered and allows the battle system to scale naturally.

## Current Multiplier Formula

```
Actual Damage = Base Damage × Defense Multiplier × Damage Reduction
Where:
  Defense Multiplier = max(0.1, 1.0 - (target_defense / 100.0))
  Damage Reduction = state.damage_reduction (property, default 1.0)
  Minimum Output = 1 damage per turn
```

### Example Calculations

| Target Defense | Defense Multiplier | Base Damage | Result |
|---|---|---|---|
| 0 | 1.0 | 10 | 10 damage |
| 20 | 0.8 | 10 | 8 damage |
| 50 | 0.5 | 10 | 5 damage |
| 80 | 0.2 | 10 | 2 damage |
| 100+ | 0.1 (capped) | 10 | 1 damage |

## State Properties

### Exported Variables (Visible in Editor)

**`state_name: String`**
- Display name of the state (e.g., "Poison", "Burn")
- Shown in UI and debug messages

**`state_description: String`**
- Description of what the state does
- Shows to players in menus

**`state_type: StateType`** (Enum)
- `DOT` - Damage over time (poison, burn, bleed)
- `COUNTER` - Counter attack mechanics
- `BUFF` - Stat increases
- `DEBUFF` - Stat decreases
- Used for categorization and future mechanics

**`damage_per_turn: int`** (Range: 0-100)
- Base damage or healing applied each turn
- Positive values = damage/DOT
- Negative values = healing/HOT
- Final damage multiplied by defense and damage_reduction

**`turns_active: int`** (Range: -1 to 99)
- How many turns the state lasts
- `-1` = infinite until cured
- `0` = expires immediately (don't use)
- `1+` = turns remaining (decrements each turn)

**`can_be_cured: bool`**
- Whether cure skills can remove this state
- `true` = removable
- `false` = permanent until expiration

**`damage_reduction: float`** (Range: 0.0-2.0, step 0.1)
- Multiplier for the damage effect
- `1.0` = normal (100%)
- `0.5` = half damage (50%)
- `2.0` = double damage (200%) - use for debuffs/weaknesses
- Applied AFTER defense calculation

## Implementation Details

### Location: `process_states()` in `battler.gd`

```gdscript
func process_states() -> void:
    var states_to_remove = []
    
    for state_name in active_states:
        var state = active_states[state_name]
        
        # Apply DOT/HOT with multipliers
        if state.damage_per_turn != 0:
            var defense_multiplier = max(0.1, 1.0 - (float(defense) / 100.0))
            var actual_damage = int(state.damage_per_turn * defense_multiplier * state.damage_reduction)
            actual_damage = max(1, actual_damage)  # Minimum 1 damage
            
            take_damage(actual_damage)
            print("[STATE] %s takes %d damage from %s (base: %d, defense_mult: %.2f, reduction: %.2f)" 
                % [character_name, actual_damage, state_name, state.damage_per_turn, defense_multiplier, state.damage_reduction])
        
        # Handle duration
        if state.turns_active > 0:
            state.turns_active -= 1
            if state.turns_active <= 0:
                states_to_remove.append(state_name)
    
    # Remove expired states
    for state_name in states_to_remove:
        remove_state(state_name)
```

## Creating Custom Damage Multiplier Systems

### Option 1: Modify `damage_reduction` Per State

**Easiest approach** - No code changes required.

1. Create a new State (.tres file)
2. Set `damage_per_turn` to your desired base value
3. Adjust `damage_reduction` to fine-tune damage:
   - `0.5` = half effectiveness
   - `1.0` = normal effectiveness
   - `1.5` = 50% stronger
   - `2.0` = double damage

**Example:** Create a "Strong Poison" with `damage_per_turn=8, damage_reduction=1.5`
- Against 0 DEF: 8 × 1.0 × 1.5 = **12 damage/turn**
- Against 50 DEF: 8 × 0.5 × 1.5 = **6 damage/turn**

### Option 2: Implement Element-Based Multiplier

**Advanced** - Modify `process_states()` to consider element types:

```gdscript
func process_states() -> void:
    var states_to_remove = []
    
    for state_name in active_states:
        var state = active_states[state_name]
        
        if state.damage_per_turn != 0:
            var defense_multiplier = max(0.1, 1.0 - (float(defense) / 100.0))
            
            # Apply element wheel for states
            var element_bonus = Formulas.element_wheel(state.element, stats.element)
            
            var actual_damage = int(state.damage_per_turn * defense_multiplier * state.damage_reduction * element_bonus)
            actual_damage = max(1, actual_damage)
            
            take_damage(actual_damage)
        
        # Duration handling...
    
    for state_name in states_to_remove:
        remove_state(state_name)
```

**Requires:** Adding `element: GlobalBattleSettings.Elements` to State class

### Option 3: Implement Attacker-Based Multiplier

**Advanced** - Store the attacker reference and apply their stats:

```gdscript
# In State class, add:
var applied_by: Battler  # Reference to who applied the state

# In process_states(), modify damage calculation:
if state.damage_per_turn != 0 and state.applied_by:
    # Apply attacker's spell power or stat bonus
    var attacker_bonus = float(state.applied_by.stats.attack) / 100.0
    var defense_multiplier = max(0.1, 1.0 - (float(defense) / 100.0))
    
    var actual_damage = int(state.damage_per_turn * defense_multiplier * state.damage_reduction * attacker_bonus)
    actual_damage = max(1, actual_damage)
    
    take_damage(actual_damage)
```

This scales poison/burn damage based on who cast it (magic users do more poison damage).

### Option 4: Implement Difficulty Scaling

**Advanced** - Different damage based on battle difficulty:

```gdscript
# In process_states(), modify calculation:
var difficulty_multiplier = 1.0
match GlobalBattleSettings.current_difficulty:
    GlobalBattleSettings.Difficulty.EASY:
        difficulty_multiplier = 0.7
    GlobalBattleSettings.Difficulty.NORMAL:
        difficulty_multiplier = 1.0
    GlobalBattleSettings.Difficulty.HARD:
        difficulty_multiplier = 1.3

var actual_damage = int(state.damage_per_turn * defense_multiplier * state.damage_reduction * difficulty_multiplier)
actual_damage = max(1, actual_damage)
```

## Balancing Tips

### For Poison/Bleed (DOT States)
- Base damage: 5-15 per turn
- Duration: 3-5 turns
- damage_reduction: 1.0 (normal)
- Should feel dangerous but not game-breaking

### For Burn (Strong DOT)
- Base damage: 8-20 per turn
- Duration: 2-4 turns
- damage_reduction: 1.2-1.5 (stronger)
- Can apply element bonus

### For Healing (HOT States)
- Base damage: 5-25 per turn (negative = healing)
- Duration: 3-5 turns
- damage_reduction: 1.0
- Consider applying healing reduction to high-defense enemies

### Against High Defense Enemies
- Defense multiplier caps at 0.1 minimum
- High defense = 90% damage reduction
- Consider using ability-based damage instead of state damage for consistency

## Testing

Use the debug output from `process_states()`:
```
[STATE] Player takes 8 damage from Poison (base: 10, defense_mult: 0.80, reduction: 1.00)
```

This shows:
- **base**: 10 damage per turn
- **defense_mult**: 0.80 (target has 20 defense)
- **reduction**: 1.00 (no damage_reduction modifier)
- **result**: 8 actual damage

## Related Systems

- **Skill Healing:** Uses `hp_delta` property directly (not affected by defense)
- **Skill Damage:** Uses `Formulas.calculate_damage()` with full stat scaling
- **SP Regeneration:** Now includes ±30% randomness (`randf_range(0.7, 1.3)`)

## Troubleshooting

**Q: States do no damage at all**
- Check `damage_per_turn` is not 0
- Check target has reasonable defense (not infinite)
- Check `can_be_cured` settings (shouldn't affect damage)

**Q: States do too much/too little damage**
- Adjust `damage_per_turn` or `damage_reduction`
- Remember: high defense targets take less DOT damage
- Test against enemies with 0, 50, and 100+ defense

**Q: State expires immediately**
- Check `turns_active` is not 0 (use -1 for infinite)
- Check state is being properly added with `apply_state()`

**Q: Healing isn't working**
- Use negative `damage_per_turn` values (e.g., -15)
- Or use Skills with `hp_delta` and `EFFECT_TYPE.HEAL`
- Skills are more reliable for healing
