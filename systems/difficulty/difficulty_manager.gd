## Difficulty Manager
## Handles difficulty scaling for damage, stats, rewards
## Look for this file in: systems/difficulty/ folder

class_name DifficultyManager
extends Node

## Difficulty multipliers (modify damage/defense based on difficulty)
static var difficulty_multipliers = {
	GlobalBattleSettings.Difficulties.EASY: {
		"player_damage": 1.25,      # Players do 25% more damage
		"enemy_damage": 0.75,       # Enemies do 25% less damage
		"enemy_defense": 0.85,      # Enemies have 15% less defense
		"experience": 0.75,         # 75% exp reward
		"gold": 0.75                # 75% gold reward
	},
	GlobalBattleSettings.Difficulties.NORMAL: {
		"player_damage": 1.0,
		"enemy_damage": 1.0,
		"enemy_defense": 1.0,
		"experience": 1.0,
		"gold": 1.0
	},
	GlobalBattleSettings.Difficulties.HARD: {
		"player_damage": 0.85,      # Players do 15% less damage
		"enemy_damage": 1.25,       # Enemies do 25% more damage
		"enemy_defense": 1.15,      # Enemies have 15% more defense
		"experience": 1.5,          # 150% exp reward
		"gold": 1.5                 # 150% gold reward
	}
	# INSANE can be added later with custom values
}

## Get multiplier for current difficulty
static func get_difficulty_multiplier(difficulty: int, stat_type: String) -> float:
	if difficulty not in difficulty_multipliers:
		return 1.0
	
	var multipliers = difficulty_multipliers[difficulty]
	if stat_type in multipliers:
		return multipliers[stat_type]
	
	return 1.0

## Get current active difficulty
static func get_active_difficulty() -> int:
	return GlobalBattleSettings.Global_Difficulty if GlobalBattleSettings.has_method("get") or "Global_Difficulty" in GlobalBattleSettings else GlobalBattleSettings.Difficulties.NORMAL

## Apply difficulty modifier to damage
static func apply_difficulty_to_damage(damage: int, modifier_type: String) -> int:
	var difficulty = get_active_difficulty()
	var multiplier = get_difficulty_multiplier(difficulty, modifier_type)
	return int(damage * multiplier)

## Apply difficulty modifier to rewards
static func apply_difficulty_to_reward(amount: int, reward_type: String) -> int:
	var difficulty = get_active_difficulty()
	var multiplier = get_difficulty_multiplier(difficulty, reward_type)
	return int(amount * multiplier)

## Set difficulty for current session
static func set_difficulty(new_difficulty: int) -> void:
	if "Global_Difficulty" in GlobalBattleSettings:
		GlobalBattleSettings.Global_Difficulty = new_difficulty
		print("Difficulty set to: ", new_difficulty)
