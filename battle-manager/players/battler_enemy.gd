extends Battler

enum AIType {AGGRESSIVE, DEFENSIVE}

@export var ai_type: AIType = AIType.AGGRESSIVE


func _ready():
	super._ready()
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

func aggressive_action(players: Array):
	var target = get_weakest_target(players)
	var damage = get_attack_damage()
	print("%s attacks %s with %d damage!" % [character_name, target.character_name, damage])
	target.take_damage(damage)

func defensive_action(players: Array):
	if float(current_health) / max_health < 0.3:
		defend()
	else:
		aggressive_action(players)

func get_weakest_target(targets: Array) -> Node:
	var weakest = null
	for target in targets:
		if target != self and (weakest == null or target.current_health < weakest.current_health):
			weakest = target
	return weakest
