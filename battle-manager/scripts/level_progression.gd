## LevelProgression
## Level-focused stat growth system - stats scale with level AND multiplier values
## NOT stat-focused (which only scales base stats without level progression)
## 
## How it works:
## - Each battler has a BASE_STATS dict (values at level 1)
## - Each battler has a STAT_MULTIPLIERS dict (growth per level)
## - Final Stat = BASE_STAT + (LEVEL - 1) * MULTIPLIER
## 
## Example: If health base is 100 and multiplier is 20:
##   - Level 1: 100 + (1-1)*20 = 100 HP
##   - Level 5: 100 + (5-1)*20 = 180 HP
##   - Level 10: 100 + (10-1)*20 = 280 HP

class_name LevelProgression

## Static dictionary for base stats at level 1 (used by all characters of a class)
static var class_base_stats = {
	# Format: "class_name": { "max_health": 100, "max_sp": 50, "attack": 10, "defense": 5, "agility": 8 }
}

## Static dictionary for stat multipliers per level (used by all characters of a class)
static var class_stat_multipliers = {
	# Format: "class_name": { "max_health": 15, "max_sp": 5, "attack": 2, "defense": 1, "agility": 1 }
}

## Calculate a single stat at given level
## Formula: base_stat + (level - 1) * multiplier
static func calculate_stat(base_stat: int, multiplier: int, level: int) -> int:
	return base_stat + (level - 1) * multiplier

## Get all calculated stats for a battler at their current level
## Returns a dictionary with all stat values
static func get_stats_at_level(base_stats: Dictionary, stat_multipliers: Dictionary, level: int) -> Dictionary:
	var calculated_stats = {}
	
	for stat_name in base_stats.keys():
		if stat_multipliers.has(stat_name):
			calculated_stats[stat_name] = calculate_stat(
				base_stats[stat_name],
				stat_multipliers[stat_name],
				level
			)
		else:
			calculated_stats[stat_name] = base_stats[stat_name]  # Keep base if no multiplier
	
	return calculated_stats

## Apply level-based stat scaling to a battler
## Updates all stats based on level and multipliers
static func apply_level_stats(battler: Battler, level: int = -1) -> void:
	if not battler or not battler.stats:
		return
	
	# Use provided level or get from battler
	var current_level = level if level > 0 else battler.stats.level
	
	# Get base stats from BattlerStats exports
	var base_stats = {
		"max_health": battler.stats.max_health,
		"max_sp": battler.stats.max_sp,
		"attack": battler.stats.attack,
		"defense": battler.stats.defense,
		"agility": battler.stats.agility
	}
	
	# Get stat multipliers from BattlerStats exports
	var stat_multipliers = {
		"max_health": battler.stats.health_multiplier,
		"max_sp": battler.stats.sp_multiplier,
		"attack": battler.stats.attack_multiplier,
		"defense": battler.stats.defense_multiplier,
		"agility": battler.stats.agility_multiplier
	}
	
	# Calculate new stats at this level
	var calculated_stats = get_stats_at_level(base_stats, stat_multipliers, current_level)
	
	# Apply to battler
	battler.max_health = calculated_stats.get("max_health", 100)
	battler.max_sp = calculated_stats.get("max_sp", 100)
	battler.attack = calculated_stats.get("attack", 10)
	battler.defense = calculated_stats.get("defense", 5)
	battler.agility = calculated_stats.get("agility", 5)
	
	# Update current health/sp to not exceed max
	battler.current_health = min(battler.current_health, battler.max_health)
	battler.current_sp = min(battler.current_sp, battler.max_sp)

## Handle level up - recalculate stats and apply bonuses
static func level_up(battler: Battler) -> void:
	if not battler or not battler.stats:
		return
	
	battler.stats.level += 1
	apply_level_stats(battler, battler.stats.level)
	
	print("%s leveled up to %d!" % [battler.character_name, battler.stats.level])
	
	# Restore full HP/SP on level up (optional, can be toggled)
	if battler.stats.has_meta("restore_on_level_up") and battler.stats.get_meta("restore_on_level_up"):
		battler.current_health = battler.max_health
		battler.current_sp = battler.max_sp

## Get experience needed for next level (scaling formula)
## Base exp requirement scales exponentially
static func get_exp_for_next_level(current_level: int, base_exp_requirement: int = 100) -> int:
	# Each level requires more exp: level * base_exp_requirement * 1.1^(level-1)
	return int(base_exp_requirement * current_level * pow(1.1, current_level - 1))

## Check if battler has enough exp to level up
static func check_level_up(battler: Battler) -> bool:
	if not battler or not battler.stats or not battler.exp_node:
		return false
	
	var exp_needed = get_exp_for_next_level(battler.stats.level)
	
	if battler.exp_node.exp_total >= exp_needed:
		battler.exp_node.exp_total -= exp_needed
		level_up(battler)
		return true
	
	return false
