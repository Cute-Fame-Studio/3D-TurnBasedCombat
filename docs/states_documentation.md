# Game States Documentation

## Overview
States are temporary conditions afflicted on battlers. They can be positive (buffs) or negative (debuffs).
Each battler has an `active_states` dictionary storing state instances by name.

---

## Active States in This System

### Damage Over Time (DOT) States

#### **Poison** 
- **Type**: DOT (Damage Over Time)
- **Effect**: Deals 6 HP damage per turn for 5 turns
- **Color**: Green
- **Visual**: Battler takes chip damage each turn
- **Cure**: Can be removed with heal/cure skills
- **Use**: Used by toxic enemies, poison-type attacks
- **Test Skill**: `test_poison.tres` - Applies instantly

#### **Burn**
- **Type**: DOT
- **Effect**: Deals fire damage per turn
- **Color**: Red/Orange
- **Visual**: Battler appears aflame
- **Use**: From fire-based attacks

#### **Bleed**
- **Type**: DOT
- **Effect**: Deals physical damage per turn from wounds
- **Color**: Red
- **Use**: From physical slashing attacks

#### **Frozen**
- **Type**: DOT + Action Prevention
- **Effect**: Deals 8 ice damage per turn AND prevents actions for 4 turns
- **Color**: Cyan/Blue
- **Visual**: Battler appears frozen, cannot act
- **Cure**: Can be broken with fire attacks or healing
- **Use**: Strong control-type status
- **Test Skill**: `test_frozen.tres` - Applies instantly
- **Strategy**: Prevents enemy turns while dealing damage

#### **Regen**
- **Type**: Healing DOT
- **Effect**: Restores HP per turn (positive DOT)
- **Color**: Green
- **Use**: Self-buff, healing spells

---

### Debuff States (Stat/Ability Reduction)

#### **Slow**
- **Type**: Debuff
- **Effect**: Reduces attack power to 70% for 5 turns
- **Color**: Blue
- **Mechanic**: Uses `power_multiplier = 0.7` to reduce damage output
- **Visual**: Battler moves sluggishly
- **Cure**: Can be removed with stat restoration
- **Use**: Defensive strategy to reduce enemy threat
- **Test Skill**: `test_slow.tres` - Applies instantly
- **Note**: When applying this state via animation, should NOT deal damage

#### **Blind**
- **Type**: Debuff
- **Effect**: Reduces hit accuracy to 60% for 4 turns
- **Color**: Gray/Muted
- **Mechanic**: Uses `hit_chance = 60.0` (60% hit rate, 40% miss rate)
- **Visual**: Battler cannot see clearly
- **Strikes**: Affected attacker has 60% hit chance instead of 100%
- **Cure**: Can be removed with healing
- **Use**: Defensive status to reduce enemy accuracy
- **Test Skill**: `test_blind.tres` - Applies instantly
- **Note**: When applying this state via animation, should NOT deal damage
- **Implementation**: Checked in damage_calculation() - rolls against hit_chance

#### **Curse**
- **Type**: Debuff  
- **Effect**: Increases damage taken by 50% for 8 turns (takes 1.5x damage)
- **Color**: Purple
- **Mechanic**: Uses `damage_taken_multiplier = 1.5`
- **Visual**: Battler appears cursed/dark
- **Vulnerability**: All incoming attacks deal more damage
- **Cure**: Can be uncursed
- **Use**: Powerful debuff for weakening boss fights
- **Note**: "Hate" in UI might be internal name

#### **Weakness**
- **Type**: Debuff
- **Effect**: Takes 50% more damage for unknown duration
- **Color**: Red/Yellow
- **Mechanic**: Already implemented in take_damage()
- **Visual**: Battler appears weakened
- **Use**: Element weakness or special vulnerability

#### **Stun**
- **Type**: Debuff (Action Prevention)
- **Effect**: Prevents action for 5 turns (paralyzed state)
- **Color**: Yellow/Gold
- **Visual**: Battler is electrified or frozen in place
- **Cure**: Can be (rarely) broken
- **Use**: Powerful control status
- **Strategy**: Disable enemy threats temporarily

---

### Buff States (Stat/Ability Enhancement)

#### **Haste**
- **Type**: Buff
- **Effect**: Increases attack power to 120% for 6 turns
- **Color**: Gold/Yellow
- **Mechanic**: Uses `power_multiplier = 1.2`
- **Visual**: Battler appears energized, glowing
- **Use**: Offensive buff to increase your damage
- **Test Skill**: `test_haste.tres` - Applies to allies
- **Strategy**: Buff allies before main fights

#### **Barrier**
- **Type**: Buff (Defensive)
- **Effect**: Reduces damage taken by 30% (takes 0.7x damage) for 7 turns
- **Color**: Blue/Silver
- **Mechanic**: Uses `damage_taken_multiplier = 0.7`
- **Visual**: Protective aura or shield effect
- **Use**: Defensive buff to weather attacks
- **Stack**: Multiple barriers might stack (depends on implementation)

---

### Action Prevention States

#### **Sleep**
- **Type**: Action Prevention
- **Effect**: Prevents battler from taking turns for 3 turns
- **Color**: Purple/Blue
- **Visual**: Battler appears asleep
- **Break Condition**: **Takes damage** → wakes up immediately
- **Cure**: Can be dispelled manually
- **Use**: Control status that breaks on damage
- **Test Skill**: `test_sleep.tres` - Applies instantly
- **Implementation**: Works as intended
  - When Sleep applies: Skip battler's turn
  - When attacked: Sleeping battler wakes up (Sleep state removed)
  - Works with all damage sources (attacks, skills, etc.)

#### **Counter** 
- **Type**: Special (Reactive)
- **Effect**: When hit by enemy attack, automatically counter-attack back
- **Color**: Gold/Orange
- **Configuration**:
  - `interrupt_attacker`: true → Counter fires while attacker is in place (Like a Dragon style)
  - `interrupt_attacker`: false → Wait for attacker to return, then counter
  - `max_counters_per_turn`: Maximum counter triggers per turn (default 2)
  - `counter_damage_multiplier`: Damage multiplier (default 1.5x = 150%)
- **Mechanics**: 
  - Triggers when `take_damage()` is called with Counter state active
  - Only triggers against enemies, NOT allies
  - Usage resets at start of each battler's turn
  - Attacker is STUNNED after counter and cannot move for 1.5 seconds
  - During stun: Attacker stays in place (allows ragdoll/knockback effects)
  - After stun: Attacker returns to original position normally
- **Resource**: 
  - Script: `database/states/counter.gd` (CounterState class)
  - Resource: `database/states/counter.tres`
- **Skill**: Uses Counter Skill (res://database/skills/counter_skill.tres)
- **Use Cases**: 
  - Defensive playstyle that punishes attackers
  - Allows player to take damage and retaliate automatically
  - Synergizes well with tanky characters
- **Implementation Notes**:
  - `state_name` must be exactly "Counter" (case-sensitive) for lookups
  - Stun flag (`is_counter_stunned`) set on attacker when counter triggers
  - `counter_stun_duration` is configurable per-battler (default 1.5s)
  - Counter skill uses EFFECT_TYPE.BUFF (state-only, no damage component)

---

## State System Architecture

### How States Work
1. **Apply** - Skill calls `apply_state()` with probability
2. **Track** - State stored in `active_states` Dictionary by `state_name`
3. **Process** - Each turn, states count down `turns_active`
4. **Remove** - When turn count reaches 0 or manually cured
5. **Effect** - State multipliers apply during damage calc and action validation

### State Properties
```gdscript
@export var state_name: String              # Unique ID ("Sleep", "Poison", etc)
@export var state_description: String       # UI tooltip text
@export var state_type: StateType           # DOT, COUNTER, BUFF, DEBUFF
@export var damage_per_turn: int            # DOT damage (0 = no damage)
@export var power_multiplier: float         # Damage multiplier (0.7 = weak, 1.2 = strong)
@export var turns_active: int               # Duration (-1 = infinite)
@export var can_be_cured: bool              # If healing removes it
@export var damage_taken_multiplier: float  # Incoming damage modifier
```

---

## Known Issues & Future Fixes

### ✅ FIXED Issues
- ✅ Test skills doing damage → Now use BUFF effect type (state-only)
- ✅ Counter doesn't trigger → State name now "Counter" (uppercase) 
- ✅ Attacker doesn't stop after counter → Stun system added (1.5s pause)
- ✅ No turn-to-face after being hit → Implemented in take_damage()
- ✅ Blind doesn't reduce hit chance → Hit chance system implemented (60% accuracy)
- ✅ Sleep doesn't wake on damage → Wake-on-damage logic added to take_damage()
- ✅ No miss chance system → Miss framework implemented with random roll

### ❌ OPEN Issues
1. **Slow/Blind animation on apply** 
   - animation_effects() triggers even for state-only skills
   - These skills shouldn't advance to target OR shouldn't trigger animation damage
   - Status: Workaround applied (advance only for enemy debuffs)

2. **State multipliers not applying to defense** 
   - Curse increases damage_taken but only for damage context
   - Barrier reduces damage but doesn't affect defense stat
   - Status: Working as intended (damage-based, not stat-based)

---

## Testing States

### Using Test Skills in Battle
Test skills are located in `database/skills/test/` and are designed for debugging state mechanics:

- `test_poison.tres` - Applies Poison (6 dmg/turn, 5 turns)
- `test_sleep.tres` - Applies Sleep (prevents actions, 3 turns)
- `test_slow.tres` - Applies Slow (70% power multiplier, 5 turns)
- `test_haste.tres` - Applies Haste (120% power multiplier, 6 turns)
- `test_frozen.tres` - Applies Frozen (8 dmg/turn + prevents actions, 4 turns)
- `test_blind.tres` - Applies Blind (reduces accuracy, 4 turns)

### Core Skills with States

- `counter_skill.tres` - Applies Counter state (defensive stance)
- `regen_skill.tres` - Applies Regen state (healing per turn)

### Testing Protocol for States

1. **Setup**: Start a battle scene
2. **Apply**: Use a test skill or state-applying skill on a target
3. **Verify Application**: 
   - Check console for `[STATE] X was afflicted with Y!` message
   - Verify state appears in target's active_states
4. **Observe Effect**:
   - For DOT states: Watch enemy health decrease each turn
   - For debuffs: Check attack damage output (should be modified)
   - For buffs: Check health restoration or stat bonuses
   - For prevention: Verify action is skipped
5. **Duration**: Verify state countdown
   - Each turn, `turns_active` should decrease
   - When reaches 0, state should be removed
6. **Removal**: 
   - Auto-remove when duration ends
   - Manual remove with cure/heal spells (if implemented)

### Counter Testing

1. **Apply Counter State**: Use Counter Skill on any battler (player or enemy)
2. **Verify State**: Check `[STATE] X was afflicted with Counter!` in console
3. **Attack Counter User**: Have another battler attack the Counter-affected battler
4. **Observe Counter**:
   - Counter should trigger automatically (no player input needed)
   - Defender should counter-attack the attacker
   - Attacker should take counter damage
   - Attacker should STOP moving (stun for ~1.5 seconds)
   - After stun, attacker returns to position normally
5. **Counter Limit**: 
   - Use counter multiple times (attacker keeps attacking)
   - Counter should only trigger up to 2 times (configurable)
   - 3rd attack should NOT trigger counter
6. **Reset**: Start new turn
   - Counter usage should reset to 0
   - Can counter again up to limit

### Debug Tips

- **State not applying?** Check console for `[STATE]` messages
  - If missing: verify state_name matches exactly (case-sensitive!)
  - If missing: check probability roll (default 100%)
- **Damage not applying?** 
  - DOT states need `damage_per_turn > 0`
  - Run `process_states()` each turn (happens automatically)
  - Check BattleManager turn processing
- **Counter not triggering?**
  - Verify attacker is ENEMY team (no ally counters)
  - Check Counter state exists in active_states dictionary
  - Verify state_name is "Counter" (uppercase!)
  - Look for `[COUNTER]` messages in console
- **Blind not reducing accuracy?**
  - Check console for `attacks X misses!` message
  - If missing: Blind state may not have hit_chance < 100
  - Verify Blind state has `hit_chance = 60.0`
  - Test with `test_blind.tres` skill
- **Sleep not waking on damage?**
  - When sleeping battler is attacked, should see `woke up from sleep after being hit!` message
  - If missing: Sleep state may not be properly set
  - Verify attacker actually deals damage (not a miss)

---

## Hit Chance & Miss System

### Hit Chance Calculation
```
hit_chance = attacker's lowest hit_chance state (or 100 if none)
roll = random(0-100)
if roll > hit_chance:
    attack misses (no damage applied)
else:
    attack hits (damage applied normally)
```

### States That Affect Hit Chance
- **Blind**: hit_chance = 60.0 (40% miss rate)
- Other accuracy debuffs can be created with hit_chance < 100

### Miss Behavior
- Indicates miss in console: `X's attack misses! (rolled Y vs hit chance Z)`
- Does NOT apply damage to target
- Does NOT trigger counter-attacks (since no damage is dealt)
- Does NOT apply state effects (if any)
- Still consumes attacker's turn
