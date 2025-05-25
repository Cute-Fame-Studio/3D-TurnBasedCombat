class_name Enemy
extends "res://battle-manager/scripts/battler_scripts/battler_ally.gd"

enum AIType {AGGRESSIVE, DEFENSIVE, CUSTOM, SMART}

@export var ai_type: AIType = AIType.AGGRESSIVE
@export var custom_ai : GDScript

func _ready():
	super._ready()
	if stats and stats.is_enemy:
		remove_from_group("players")
		add_to_group("enemies")

func choose_action():
	var all_players = get_tree().get_nodes_in_group("players")
	var valid_targets = all_players.filter(func(p): return not p.is_in_group("enemies"))
	
	match ai_type:
		AIType.AGGRESSIVE:
			aggressive_action(valid_targets)
		AIType.DEFENSIVE:
			defensive_action(valid_targets)
		AIType.CUSTOM:
			custom_action(valid_targets)
		AIType.SMART:
			smart_action(valid_targets)

func aggressive_action(players: Array):
	var target = get_weakest_target(players)
	if target:
		if default_attack:
			use_skill(default_attack, target)
		else:
			attack_anim(target)

func defensive_action(players: Array):
	if float(current_health) / max_health < 0.3:
		defend()
	else:
		aggressive_action(players)

func smart_action(players: Array):
	pass

func custom_action(players: Array):
	pass

func get_weakest_target(targets: Array) -> Node:
	var weakest = null
	for target in targets:
		if target != self and (weakest == null or target.current_health < weakest.current_health):
			weakest = target
	return weakest
