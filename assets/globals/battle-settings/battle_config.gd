## Battle Configuration Resource
## Pass this to battles to customize behavior, starting states, environmental effects
## Look for this file in: assets/globals/battle-settings/ folder
## Usage: Create a .tres file instance and pass to GlobalBattleSettings.set_battle_config()

class_name BattleConfig
extends Resource

## General Configuration
@export var battle_name: String = "Battle"
@export var battle_description: String = ""

## Starting State Modifiers - Apply states to combatants before battle starts
@export var initial_ally_states: Array[State] = []
@export var initial_enemy_states: Array[State] = []

## Environmental Effects - Multipliers applied during battle
@export_range(0.1, 3.0, 0.1) var ally_damage_multiplier: float = 1.0  ## Player damage dealt
@export_range(0.1, 3.0, 0.1) var enemy_damage_multiplier: float = 1.0  ## Enemy damage dealt
@export_range(0.1, 3.0, 0.1) var ally_defense_multiplier: float = 1.0  ## Player defense
@export_range(0.1, 3.0, 0.1) var enemy_defense_multiplier: float = 1.0  ## Enemy defense

## Difficulty Override (trumps global difficulty if set)
@export var override_difficulty: bool = false
@export var difficulty: GlobalBattleSettings.Difficulties = GlobalBattleSettings.Difficulties.NORMAL

## Rewards Modifier
@export_range(0.1, 5.0, 0.1) var experience_multiplier: float = 1.0
@export_range(0.1, 5.0, 0.1) var gold_multiplier: float = 1.0

## Custom Flags for scripted battles/cutscenes
@export var is_story_battle: bool = false
@export var allow_escape: bool = true
@export var custom_tags: PackedStringArray = []

## Helper function to apply this config
func apply_config_to_battlers(allies: Array, enemies: Array) -> void:
	# Apply starting states to allies
	for ally in allies:
		if ally is Battler:
			for state in initial_ally_states:
				if state:
					BattlerCombatHelper.apply_state(ally, state)
	
	# Apply starting states to enemies
	for enemy in enemies:
		if enemy is Battler:
			for state in initial_enemy_states:
				if state:
					BattlerCombatHelper.apply_state(enemy, state)
