class_name Skill
extends Resource

enum TARGETS_TYPES {
	MULTIPLE_TARGETS = 0,
	SINGLE_TARGETS = 1,
	ALL_TARGETS = 2
}

## General Information  
@export var skill_name : String = ""
@export var description : String = ""
@export var skill_color : String = ""
@export var skill_tags : String = ""
@export var icon : Resource

## Mechanics  
@export var base_power : int = 0
@export var critical_rate : int = 0
@export var hit_chance : int = 100
@export var sp_cost : int = 0
@export var hp_cost : int = 0
@export var element : GlobalBattleSettings.Elements = GlobalBattleSettings.Elements.Physical
@export var target_type : TARGETS_TYPES = TARGETS_TYPES.SINGLE_TARGETS
@export var skill_type : GlobalBattleSettings.SkillTypes = GlobalBattleSettings.SkillTypes.SKILLS

## Effects
@export var hp_delta : int = 0  # Positive for healing, negative for HP cost
@export var sp_delta : int = 0  # Positive for SP restore, negative for SP cost
@export var effect_type : String = "Damage"  # Damage, Heal, Buff, etc.

## Animation & Visuals
@export var animation_name : String = ""

func can_use(user: Node) -> bool:
	# Change current_hp to current_health to match battler_ally.gd
	if hp_cost > 0 and user.current_health <= hp_cost:
		return false
	if sp_cost > 0 and user.current_sp <= sp_cost:
		return false
	return true

func apply_costs(user: Node) -> void:
	if hp_cost > 0:
		user.current_health -= hp_cost
	if sp_cost > 0:
		user.current_sp -= sp_cost
