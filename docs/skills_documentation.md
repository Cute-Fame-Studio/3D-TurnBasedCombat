# Skills Documentation

## Overview
Skills are special actions that battlers can use in combat. Each skill has a target type, effect type, and optional state application. Skills are differentiated from basic attacks and can consume resources or have cooldowns.

---

## Skill Properties

### Core Attributes
```gdscript
@export var skill_name: String                      # Display name
@export var description: String                     # Flavor text / tooltip
@export var base_power: int                         # Base damage or effect magnitude
@export var sp_cost: int = 0                        # Spirit Points cost
@export var hp_cost: int = 0                        # Health cost (sacrifice-type skills)
```

### Effect Configuration
```gdscript
enum EFFECT_TYPE { DAMAGE = 0, HEAL = 1, BUFF = 2 }
@export var effect_type: int                        # What the skill does
@export var target_type: int                        # Who it targets (Self/Single/All)
```

### State Application
```gdscript
@export var applies_state: State                    # State to apply on hit
@export var state_apply_chance: float = 100.0       # Chance to apply (0-100)
```

### Animation
```gdscript
@export var animation_name: String                  # Animation to play on use
```

---

## Skill Effect Types

### **DAMAGE (0)** - Offensive Attacks
- **Behavior**: Deals damage to target(s)
- **Mechanics**:
  - Damage calculated through `Formulas.physical_damage()`
  - Can apply state on hit if configured
  - Animation callback triggers damage application
  - Attacker advances toward target before attacking
- **Examples**: Normal Attack, Fireball, Slash

### **HEAL (1)** - Restorative Abilities
- **Behavior**: Restores HP to target(s)
- **Mechanics**:
  - Healing calculated and applied immediately
  - Can apply beneficial states (Regen, Barrier)
  - Does not deal damage
  - Attacker does NOT advance to target
- **Formula**: `min(amount, max_health - current_health)`
- **Examples**: Heal Spell, Full Restore, Regenerate

### **BUFF (2)** - State-Only Abilities
- **Behavior**: Applies states without dealing damage
- **Mechanics**:
  - No damage component
  - Applies configured state with chance
  - Does NOT trigger damage callbacks
  - Attacker advances toward target only if debuffing enemies
- **Application**: 
  - Self-buffs: No movement required
  - Enemy debuffs: Normal advance and attack animation
  - Ally buffs: No advance
- **Examples**: Counter, Haste, Curse, Slow

---

## Target Types

### **SELF (0)** - Self-Targeting
- Only affects the user
- Used for buffs and passive abilities
- Examples: Counter, Haste, Barrier

### **SINGLE_ALLY (1)** - Single Ally
- Targets one friendly battler
- Used for support and healing
- Examples: Single Heal, Ally Buff

### **SINGLE_ENEMY (2)** - Single Enemy
- Targets one enemy
- Most common offensive type
- Examples: Attack, Fireball, Curse

### **ALL_ALLIES (3)** - All Allies
- Targets entire friendly party
- Used for group support
- Examples: Group Heal, Mass Buff

### **ALL_ENEMIES (4)** - All Enemies
- Targets entire enemy group
- Used for AoE attacks
- Examples: Meteor, Mass Curse

---

## Core Skills

### **Normal Attack**
- **Type**: DAMAGE
- **Target**: SINGLE_ENEMY
- **Power**: 50
- **Effect**: Basic physical attack, no state application
- **Animation**: "attack"
- **Resource**: `database/skills/normal_attack.tres`
- **Use**: Default attack for all battlers
- **Behavior**: 
  - Battler advances to target
  - Plays attack animation
  - Deals physical damage
  - Returns to original position after

### **Fireball**
- **Type**: DAMAGE
- **Target**: SINGLE_ENEMY
- **Power**: 65
- **Effect**: Fire-based magical attack
- **Animation**: "attack"
- **Resource**: `database/skills/fireball.tres`
- **Use**: Offensive spell with higher power than basic attack
- **Behavior**: Same as Normal Attack, slightly more powerful

### **Simple Heal**
- **Type**: HEAL
- **Target**: SINGLE_ALLY
- **Power**: 40
- **Effect**: Restores HP without animation
- **Resource**: `database/skills/simple_heal.tres`
- **Use**: Basic healing in combat
- **Behavior**:
  - Instantly restores health
  - No advance to target
  - No damage animation

### **Counter**
- **Type**: BUFF (state-only)
- **Target**: SELF
- **Effect**: Applies Counter state to user
- **Animation**: "attack"
- **Resource**: `database/skills/counter_skill.tres`
- **Use**: Defensive stance that triggers counter-attacks
- **Applied State**: Counter state from `database/states/counter.tres`
- **Behavior**:
  - User plays attack animation (stance)
  - Counter state applied with 100% chance
  - Counter triggers on next incoming physical attack
  - Can counter up to 2 times per turn
- **Mechanics**:
  - When attacked: Automatically counter if state active
  - Attacker gets stunned for 1.5 seconds after counter
  - Counter damage multiplier: 1.5x (150% of counter power)

### **Regen Skill**
- **Type**: BUFF (state-only)
- **Target**: SELF or SINGLE_ALLY
- **Effect**: Applies Regen state
- **Resource**: `database/skills/regen_skill.tres`
- **Use**: Long-term healing buff
- **Applied State**: Regen (heals per turn)
- **Behavior**: Healing DOT that lasts 8 turns

---

## Test Skills

Test skills are created for debugging and balancing purposes. They all have `effect_type = BUFF (2)` so they apply states without dealing damage.

### **test_poison.tres**
- **Target**: ALL_ENEMIES
- **State Applied**: Poison
- **Effect**: 6 damage/turn for 5 turns
- **Purpose**: Test DOT mechanics

### **test_slow.tres**
- **Target**: ALL_ENEMIES
- **State Applied**: Slow
- **Effect**: Reduces power to 70% for 5 turns
- **Purpose**: Test debuff multiplier mechanics

### **test_haste.tres**
- **Target**: ALL_ALLIES
- **State Applied**: Haste
- **Effect**: Increases power to 120% for 6 turns
- **Purpose**: Test buff multiplier mechanics

### **test_sleep.tres**
- **Target**: ALL_ENEMIES
- **State Applied**: Sleep
- **Effect**: Prevents actions for 3 turns
- **Purpose**: Test action prevention mechanics

### **test_frozen.tres**
- **Target**: ALL_ENEMIES
- **State Applied**: Frozen
- **Effect**: 8 damage/turn + prevents actions for 4 turns
- **Purpose**: Test combined DOT + action prevention

### **test_blind.tres**
- **Target**: ALL_ENEMIES
- **State Applied**: Blind
- **Effect**: Reduces hit accuracy for 4 turns
- **Purpose**: Test accuracy debuff (mechanics incomplete)

---

## Skill Usage & Execution

### Damage Skill Flow
```
1. Use Skill (selected in UI)
2. Target Selection (if needed)
3. Advance to target (movement animation)
4. Play attack animation
5. Animation callback triggers damage
6. Apply state (if any, with chance)
7. Wait for counter-attacks (if any)
8. Return to original position
9. Complete action
```

### Buff Skill Flow
```
1. Use Skill (selected in UI)
2. Target Selection (if self, skip)
3. Advance to target (if enemy debuff only)
4. Play animation
5. Apply state with probability
6. Animation finishes
7. Return to position (if advanced)
8. Complete action
```

### Healing Skill Flow
```
1. Use Skill (selected in UI)
2. Target Selection (if needed)
3. Play animation (no advance)
4. Apply healing immediately
5. Animation finishes
6. Complete action
```

---

## State Application Mechanics

### Application Chance
- Each skill has `state_apply_chance` (0-100)
- When skill executes, random check determines if state applies
- Failure is silent (no message, just no state)
- Default: 100% (always applies)

### State Duplication
- When state applies, it's duplicated to prevent shared instances
- Each battler gets their own state copy
- State properties like `turns_active` are independent

### Multi-Target Application
- AoE skills apply state to each target independently
- Each target has separate chance check
- Some ALL_TARGETS skills may apply to specific team only
  - ALL_ENEMIES: Only to enemies
  - ALL_ALLIES: Only to allies

---

## Skill Creation Guide

### Basic Damage Skill
```gdscript
# Create new .tres file
# Set type to Skill resource
effect_type = 0          # DAMAGE
target_type = 2          # SINGLE_ENEMY
base_power = 60
applies_state = null     # No state
```

### Buff Skill (State-Only)
```gdscript
effect_type = 2          # BUFF
target_type = 0          # SELF (or 2 for enemy debuff)
base_power = 0           # No damage
applies_state = [Your State Resource]
state_apply_chance = 100
```

### Healing Skill
```gdscript
effect_type = 1          # HEAL
target_type = 1          # SINGLE_ALLY (or 3 for ALL)
base_power = 50          # Healing amount
applies_state = null     # Usually no state
```

---

## Known Limitations & Future Improvements

1. **No MP/SP Cost Implementation** - Skills don't consume SP
2. **No Skill Cooldowns** - Skills can spam infinitely
3. **No Hybrid Skills** - Cannot mix DAMAGE + HEAL
4. **Limited AoE** - No single-target AoE variations
5. **No Skill Trees** - No progression or unlocking
6. **No Accuracy Check** - All attacks connect unless blinded
7. **No Scaling** - Damage doesn't scale with stats properly

---

## Testing Skills in Battle

1. Open battle scene
2. Select skill from UI
3. Choose target (if required)
4. Observe animation and effect
5. Check console for state application messages
6. Verify damage numbers and health bars
7. Monitor state duration (should decrement each turn)

---

## Testing Specific Mechanics

### Testing Blind & Hit Chance

1. **Setup**: Use `test_blind.tres` skill on an enemy
2. **Verify Application**: Check console for `[STATE] Enemy was afflicted with Blind!`
3. **Test Attack**: Have that enemy attack a player
4. **Observe**:
   - Should see console messages: `X's attack misses! (rolled Y vs hit chance 60.0)`
   - Some attacks will miss (40% miss rate)
   - Enemy takes turn even on miss
   - Missed attacks deal 0 damage
5. **State Duration**: Blind lasts 4 turns, then accuracy returns to normal
6. **Verification**: Roll multiple attacks to see ~40% miss rate

### Testing Sleep & Wake

1. **Setup**: Use `test_sleep.tres` skill on an enemy
2. **Verify Application**: Check console for `[STATE] Enemy was afflicted with Sleep!`
3. **Observe Sleep**:
   - Enemy should skip their turn (not appear in turn order)
   - Sleep lasts 3 turns normally
4. **Test Wake on Damage**: Have player attack the sleeping enemy
5. **Verify Wake**:
   - Should see: `Enemy woke up from sleep after being hit!`
   - Enemy takes the damage normally
   - Sleep state is removed immediately
   - Enemy can act again next turn
6. **Alternative**: If Sleep reaches 0 turns naturally (not broken by damage), it expires normally

