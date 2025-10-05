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
	var target = choose_target(this, players)
	if target:
		battle_manager.current_target = target
		battle_manager.battler_attacking = true
		this.attack_anim(target)

func defensive_action(this:Battler, players: Array, battle_manager:BattleManager):
	if float(this.current_health) / this.max_health < 0.3:
		this.defend()
	else:
		aggressive_action(this, players, battle_manager)

func choose_target(this:Battler, targets: Array) -> Node:
	print("=== AI TARGET SELECTION ===")
	print("AI Character: ", this.character_name)
	print("AI Intelligence: ", this.intelligence)
	print("Available targets: ", targets.size())
	for target in targets:
		if target is Battler:
			print("  - ", target.character_name, " (HP: ", target.current_health, "/", target.max_health, ")")
	
	# Filter out defeated targets
	var valid_targets = []
	for target:Battler in targets:
		if target != this and !target.is_defeated():
			valid_targets.append(target)
	
	if valid_targets.is_empty():
		print("No valid targets found!")
		return null
	
	# Use intelligence to determine targeting strategy
	var intelligence = this.intelligence
	var rand_value = randi() % 100
	
	print("Random value: ", rand_value, " vs Intelligence: ", intelligence)
	
	if rand_value < intelligence:
		# Smart targeting - choose based on strategy
		var chosen = get_weakest_target(valid_targets)
		print("Smart targeting chose: ", chosen.character_name if chosen else "NULL")
		return chosen
	else:
		# Random targeting - choose any valid target
		var chosen = valid_targets[randi() % valid_targets.size()]
		print("Random targeting chose: ", chosen.character_name if chosen else "NULL")
		return chosen

func get_weakest_target(targets: Array) -> Node:
	var weakest = null
	for target:Battler in targets:
		if target != self and (weakest == null or target.current_health < weakest.current_health):
			weakest = target
	return weakest
