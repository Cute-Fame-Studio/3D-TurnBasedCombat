## [color=green]AI Manager[/color]
## [br][br]
## This class manages AI action selection based on Skills available to the battler,
## the battler's Intelligence, and AI Type.
## [br][br]
## Logic to handle decision-making for NPCs in combat should be put in here.
extends Node


# Pulled from Enemy (deprecated/removed class)
func choose_action(this:Battler, opposing_team:Array, _ally_team:Array, battle_manager:BattleManager) -> void:
	battle_manager.current_battler = this
	match this.ai_type:
		Battler.AIType.AGGRESSIVE:
			aggressive_action(this, opposing_team, battle_manager)
		Battler.AIType.DEFENSIVE:
			defensive_action(this, opposing_team, battle_manager)

func aggressive_action(this:Battler, players: Array, battle_manager:BattleManager):
	var target = get_weakest_target(players)
	if target:
		battle_manager.current_target = target
		battle_manager.battler_attacking = true
		this.attack_anim(target)

func defensive_action(this:Battler, players: Array, battle_manager:BattleManager):
	if float(this.current_health) / this.max_health < 0.3:
		this.defend()
	else:
		aggressive_action(this, players, battle_manager)

func get_weakest_target(targets: Array) -> Node:
	var weakest = null
	for target:Battler in targets:
		if target != self and (weakest == null or target.current_health < weakest.current_health):
			weakest = target
	return weakest
