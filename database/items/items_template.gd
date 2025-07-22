class_name Item
extends Resource

enum TARGETS_TYPES {
	MULTIPLE_TARGETS = 0,
	SINGLE_TARGETS = 1,
	ALL_TARGETS = 2
}

## General Information  
@export var item_name : String = ""
@export var description : String = ""
@export var item_tags : String = ""
@export var icon : Resource
@export var is_battle_item:bool = true
@export var is_key_item:bool = false:
	set(key_item):
		is_key_item = key_item
		is_stackable = !key_item
@export var is_stackable:bool = true

## Mechanics  
@export var base_power : int = 0
@export var critical_rate : int = 0
@export var effectiveness : int = 100
@export var element : GlobalBattleSettings.Elements = GlobalBattleSettings.Elements.Physical
@export var target_type : TARGETS_TYPES = TARGETS_TYPES.SINGLE_TARGETS
@export var skill_type : GlobalBattleSettings.ItemTypes = GlobalBattleSettings.ItemTypes.HEALING

## Effects
@export var hp_delta : int = 0  # Positive for healing, negative for HP cost
@export var sp_delta : int = 0  # Positive for SP restore, negative for SP cost
@export var effect_type : String = "Damage"  # Damage, Heal, Buff, etc.

## Animation & Visuals
@export var animation_name : String = ""
