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
@export var formula : String 
@export var element : GlobalBattleSettings.Elements

## Effects
@export var hp_delta : int = 0  # Positive for healing, negative for HP cost
@export var sp_delta : int = 0  # Positive for SP restore, negative for SP cost
@export var effect_type : String = "Damage"  # Damage, Heal, Buff, etc.

## Animation & Visuals
@export var animation_name : String = ""

func can_use(user) -> bool:
	return user.current_sp >= abs(sp_cost) && user.current_hp > abs(hp_cost)

func apply_costs(user) -> void:
	user.current_hp += hp_delta
	user.current_sp += sp_delta
