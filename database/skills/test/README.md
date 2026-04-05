# Test Skills Folder

## Purpose
These skills are designed to quickly test individual state mechanics in battle.

## Skills Included

### test_sleep.tres
- **Effect**: Applies Sleep state (prevents action for 3 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Test**: Use on enemy, verify they skip turns

### test_slow.tres
- **Effect**: Applies Slow state (reduces damage to 70% for 5 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Test**: Use on enemy, their attacks should do less damage

### test_poison.tres
- **Effect**: Applies Poison state (6 damage per turn for 5 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Test**: Use on enemy, watch damage numbers each turn

### test_haste.tres
- **Effect**: Applies Haste state (increases damage to 120% for 6 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Target**: Single ally
- **Test**: Use on yourself, your attacks should do more damage

### test_frozen.tres
- **Effect**: Applies Frozen state (prevents action & 8 ice damage per turn for 4 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Test**: Use on enemy, verify they can't act AND take damage

### test_blind.tres
- **Effect**: Applies Blind state (reduces hit accuracy for 4 turns)
- **Cost**: 1 SP
- **Animation**: apply_to_ally
- **Test**: Use on enemy, their attacks should miss more often
- **Note**: Hit chance reduction not yet implemented

---

## Testing Protocol

1. Create a simple battle scenario
2. Select each test skill one by one
3. Apply to appropriate target (enemy for debuffs, self/ally for buffs)
4. Observe:
   - State applies to target
   - State description shows in UI
   - State count ticks down each turn
   - Effect triggers correctly (damage, miss, stat reduction, etc.)
   - State removes when duration ends
5. Report any issues

## No Damage Policy
These skills use **BUFF effect type** which means:
- ✅ They apply states
- ✅ They use "apply_to_ally" animation
- ❌ They do NOT apply movement
- ❌ They do NOT deal damage
- ❌ They use simple animations

This allows testing pure state mechanics without confounding factors.
