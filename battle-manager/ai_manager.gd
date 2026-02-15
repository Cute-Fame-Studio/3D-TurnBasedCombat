## [color=green]AI Manager[/color]
## [br][br]
## This class manages AI action selection based on Skills available to the battler,
## the battler's Intelligence, and AI Type.
## [br][br]
## Logic to handle decision-making for NPCs in combat should be put in here.
extends Node


# Pulled from Enemy (deprecated/removed class)
func choose_action(character:Battler, available_targets: Array, all_enemies: Array, battle_manager:BattleManager):
	print("=== AI TARGET SELECTION ===")
	print("AI Character: ", character.character_name)
	print("AI Intelligence: ", character.intelligence)
	print("Available targets: ", available_targets.size())
	for target in available_targets:
		if target is Battler:
			print("  - ", target.character_name, " (HP: ", target.current_health, "/", target.max_health, ")")
	
	# Choose action based on AI type
	match character.ai_type:
		Battler.AIType.AGGRESSIVE:
			aggressive_action(character, available_targets, battle_manager)
		Battler.AIType.DEFENSIVE:
			defensive_action(character, available_targets, battle_manager)
		_:
			aggressive_action(character, available_targets, battle_manager)

func aggressive_action(character:Battler, players: Array, battle_manager:BattleManager):
	var target = choose_target(character, players)
	if target:
		battle_manager.current_target = target
		battle_manager.current_character = character
		battle_manager.queued_action = "attack"  # SET THIS!
		battle_manager.battler_attacking = true
		character.attack_anim(target)

func defensive_action(character:Battler, players: Array, battle_manager:BattleManager):
	if float(character.current_health) / character.max_health < 0.3:
		character.defend()
	else:
		aggressive_action(character, players, battle_manager)

func choose_target(character:Battler, targets: Array) -> Node:
	print("=== AI TARGET SELECTION ===")
	print("AI Character: ", character.character_name)
	print("AI Intelligence: ", character.intelligence)
	print("Available targets: ", targets.size())
	for target in targets:
		if target is Battler:
			print("  - ", target.character_name, " (HP: ", target.current_health, "/", target.max_health, ")")
	
	# Filter out defeated targets
	var valid_targets = []
	for target:Battler in targets:
		if target != character and !target.is_defeated():
			valid_targets.append(target)
	
	if valid_targets.is_empty():
		print("No valid targets found!")
		return null
	
	# Use intelligence to determine targeting strategy
	var intelligence = character.intelligence
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
