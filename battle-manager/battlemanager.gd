extends Node3D

var players: Array = []
var enemies: Array = []
var turn_order: Array = []
var current_turn: int = 0

var current_battler
var default_anim = "Locomotion-Library/idle2"

@onready var hud: CanvasLayer = $BattleHUD

func _ready():
	if not hud:
		push_error("BattleHUD node not found. Please make sure it's added to the scene.")
		return

	if not hud.is_connected("action_selected", _on_action_selected):
		hud.action_selected.connect(_on_action_selected)

	initialize_battle()

func initialize_battle():
	players = get_tree().get_nodes_in_group("players")
	enemies = get_tree().get_nodes_in_group("enemies")
	
	for player in players:
		hud.on_add_character(player)
		player.battle_idle()
	
	# Ensure players are at the start of the turn order
	turn_order = players + enemies
	
	if enemies.size() > 0:
		hud.on_start_combat(enemies[0])  # Assuming single enemy for now
		enemies[0].battle_idle()

	start_next_turn()

func start_next_turn():
	if is_battle_over():
		end_battle()
		return

	var current_character = turn_order[current_turn]
	current_battler = current_character
	
	if current_character.is_defeated():
		turn_order.erase(current_character)
		current_turn = current_turn % turn_order.size()
		start_next_turn()
		return
	
	if current_character in players:
		player_turn(current_character)
	else:
		enemy_turn(current_character)

	update_hud()

func player_turn(character):
	hud.set_active_character(character)
	hud.show_action_buttons(character)

func _on_action_selected(action: String, target):
	print("Action selected: ", action, " Target: ", target.name if target else "None")
	var current_character = turn_order[current_turn]
	print("Current character: ", current_character.name)
	match action:
		"attack":
			perform_attack(current_character, target)
		"defend":
			perform_defend(current_character)
	
	end_turn()

func perform_attack(attacker, target):
	# current_anim.play("Locomotion-Library/attack1")
	attacker.attack_anim()
	var damage = attacker.get_attack_damage()
	print("%s attacks %s for %d damage!" % [attacker.character_name, target.character_name, damage])
	target.take_damage(damage)
	update_hud()

func perform_defend(character):
	character.defend()
	print("%s is defending!" % character.character_name)

func enemy_turn(character):
	var target = players[randi() % players.size()]  # Choose a random player to attack
	perform_attack(character, target)
	end_turn()

func end_turn():
	await current_battler.wait_attack()
	# if turn_order[current_turn].is_defending == false:
		# await current_anim.animation_finished
		# battle_idle(turn_order[current_turn])

	current_turn = (current_turn + 1) % turn_order.size()
	start_next_turn()

func update_hud():
	hud.update_character_info()
	if turn_order[current_turn] in players:
		hud.show_action_buttons(turn_order[current_turn])
	else:
		hud.hide_action_buttons()

func is_battle_over():
	return are_all_defeated(players) or are_all_defeated(enemies)

func are_all_defeated(characters: Array):
	for character in characters:
		if not character.is_defeated():
			return false
	return true

func end_battle():
	if are_all_defeated(enemies):
		hud.show_battle_result("Victory! All enemies have been defeated.")
		for player in players:
			player.gain_experience(100)
	elif are_all_defeated(players):
		hud.show_battle_result("Game Over. All players have been defeated.")
	hud.hide_action_buttons()
