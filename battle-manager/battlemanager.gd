class_name BattleManager
extends Node3D

enum BattleEndCondition { WIN, DEFEAT, ESCAPE }

var skip_turn = false # Please please please, Change the functionality or entirely remove this down the line.
var players: Array[Battler] = []
var enemies: Array[Battler] = []
var turn_order: Array[Battler] = []
var current_turn: int = 0

var current_character:Battler
var current_target:Battler
var in_target_selection:bool = false
var in_menu_selection:bool = false

@onready var ActionButtons = find_child("ActionButtons")
# For referencing and setting variables in the battle settings.
@onready var battle_settings = GlobalBattleSettings

var current_battler
# Defualt animation should check for weapon's later down the road, And adapt to using them with unique animations.
@export var default_animation = "Locomotion-Library/idle2" # Unused, But i reccomend gettomg the stats and animation from the database.
@export var default_attack:Skill
# Added by repo owner, Fame. To test compatibility with returning after a battle.
@export var game_map = "res://replace/regular_map/backtogame.tscn"
@onready var hud: BattleHud = $BattleHUD

# Toggles For Battles
@export_group("Toggle Buttons")
@export var attack_toggle: bool = true
@export var skills_toggle: bool = true
@export var defend_toggle: bool = true
@export var item_toggle: bool = true
@export var run_toggle: bool = true

var defending_players = ["ally_name", "null"]

var is_animating: bool = false

func _ready():
	add_to_group("battle_manager")
	SignalBus.select_target.connect(target_selected)
	
	if not hud:
		push_error("BattleHUD node not found. Please make sure it's added to the scene.")
		return
	hud.action_selected.connect(_on_action_selected)
	hud.menu_opened.connect(_do_menu_selection)
	for player in players:
		if not player.anim_damage.is_connected(_on_anim_damage):
			player.anim_damage.connect(_on_anim_damage)
	initialize_battle()
	# Checking Toggles!
	ActionButtons.get_node("Attack").disabled = not attack_toggle
	ActionButtons.get_node("Skills").disabled = not skills_toggle
	ActionButtons.get_node("Defend").disabled = not defend_toggle
	ActionButtons.get_node("Items").disabled = not item_toggle
	ActionButtons.get_node("Run").disabled = not run_toggle

func _input(event: InputEvent) -> void:
	# Cancel is currently bound to Escape key
	if event.is_action_pressed("Cancel"):
		print("Pressed cancel")
		if in_target_selection:
			print("Cancelling Target Selection")
			_cancel_action_target_selection()
		elif in_menu_selection:
			print("Cancelling Menu Selection")
			_cancel_menu_selection()
	# Confirm is currently bound to Enter key
	elif event.is_action_pressed("Confirm") and in_target_selection and current_target:
		if !queued_action.is_empty() and (queued_skill or queued_item):
			_use_action_on_target()
		else:
			printerr("MANAGER: Action and/or Skill/Item not queued!")
			print("Action: ", queued_action)
			print("Skill: ", queued_skill)
			print("Item: ", queued_item)

func initialize_battle():
	# Get all nodes and convert to Battler arrays
	players = []
	enemies = []
	
	for node in get_tree().get_nodes_in_group("players"):
		if node is Battler:
			players.append(node as Battler)
	
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Battler:
			enemies.append(node as Battler)
	
	for player in players:
		print("Have players: ", players)
		hud.on_add_character(player)
		player.battle_idle()
		player.anim_damage.connect(_on_anim_damage)
	
	# Ensure players are at the start of the turn order
	turn_order = players + enemies
	print("Current turn order: ", turn_order)
	
	for enemy in enemies:
		hud.on_start_combat(enemy)
		enemy.battle_idle()
		enemy.anim_damage.connect(_on_anim_damage)

	start_next_turn()

func count_allies():
	# For now, Should be one.
	battle_settings.ally_party = 1

# See _ready() -> SignalBus.select_target.connect() ... Emitted from Battler
func target_selected(target: Battler) -> void:
	print("=== BATTLE MANAGER TARGET SELECTED ===")
	print("Received target: ", target.character_name)
	print("In target selection: ", in_target_selection)
	print("Target is selectable: ", target.is_selectable)
	
	if !in_target_selection or !target.is_selectable:
		print("Target selection rejected - not in selection or not selectable")
		return
		
	# Clear ALL targets' selection states first - only ONE highlight allowed
	for battler in valid_targets:
		if battler is Battler:
			battler.deselect_as_target()
	
	# Clear controller target reference
	current_controller_target = null
	
	# Save this as the last selected target for future reference
	last_selected_target = target
	
	# Update keyboard index to match mouse selection
	if target in valid_targets:
		keyboard_target_index = valid_targets.find(target)
	
	current_target = target
	print("Set current_target to: ", current_target.character_name)
	print("About to call _use_action_on_target")
	print("=== VISUAL CONFIRMATION ===")
	print("Target with cyan highlight should be: ", target.character_name)
	print("Target that will be attacked: ", current_target.character_name)
	_use_action_on_target()

func start_next_turn():
	if is_battle_over():
		if all_defeated(players):
			end_battle(BattleEndCondition.DEFEAT)
		elif all_defeated(enemies):
			end_battle(BattleEndCondition.WIN)
		else:
			#Fallthrough
			end_battle()
		return

	current_character = turn_order[current_turn]
	current_battler = current_character
	
	if current_character.is_defeated():
		turn_order.erase(current_character)
		current_turn = current_turn % turn_order.size()
		start_next_turn()
		return
	
	if current_character in players:
		print("Player's turn")
		player_turn(current_character)
	else:
		print("Enemy's turn")
		enemy_turn(current_character)
	
	update_hud()

func player_turn(character):
	count_allies()
	hud.set_activebattler(character)
	hud.show_action_buttons(character)

var queued_action:String
var queued_skill:Skill
var queued_item:Item
func _on_action_selected(action: String, usable:Resource = current_character.default_attack):
	print("=== ACTION SELECTED ===")
	print("Action: ", action)
	print("Usable: ", usable)
	print("Current character: ", current_character.character_name)
	
	match action:
		"defend":
			current_character.defend()
			end_turn()
			return
		"run":
			escape_battle()
			return
	
	queued_action = action
	if action == "attack":
		if current_character.default_attack:
			queued_skill = current_character.default_attack
		else:
			queued_skill = default_attack
	if usable is Skill:
		queued_skill = usable
		print("Set queued_skill to: ", queued_skill.skill_name)
	elif usable is Item:
		queued_item = usable
	_do_target_selection()

var current_controller_target: Battler = null
var valid_targets: Array = []  # Array of Battler objects
var current_default_selector: Battler = null  # Track who has the default selection
var last_selected_target: Battler = null  # Remember last target for next selection
var keyboard_target_index: int = 0  # Track keyboard navigation position

# Modify _do_target_selection to set target validity
func _do_target_selection() -> void:
	print("\n=== Starting Target Selection ===")
	print("DEBUG: enemies array before target selection: ", enemies)
	print("DEBUG: players array before target selection: ", players)
	in_target_selection = true
	current_target = null
	valid_targets.clear()
	
	# First, clear all targeting states
	for battler in get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies"):
		if battler is Battler:
			battler.clear_all_selections()
			battler.is_valid_target = false
			battler.is_selectable = false
	
	# Get fresh data from scene to avoid array corruption issues
	var current_enemies: Array = []
	var current_players: Array = []
	
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Battler:
			current_enemies.append(node as Battler)
	
	for node in get_tree().get_nodes_in_group("players"):
		if node is Battler:
			current_players.append(node as Battler)
	
	# Set valid targets based on skill type with proper validation
	if queued_skill:
		print("=== SKILL TARGETING ===")
		print("Skill name: ", queued_skill.skill_name)
		print("Skill target type: ", queued_skill.target_type)
		print("Current character in players: ", current_character in current_players)
		print("Current enemies: ", current_enemies)
		print("Current players: ", current_players)
		
		# Check if skill can be used at all
		print("Checking if skill can be used...")
		print("Current character SP: ", current_character.current_sp)
		print("Current character HP: ", current_character.current_health)
		print("Skill SP cost: ", queued_skill.sp_cost)
		print("Skill HP cost: ", queued_skill.hp_cost)
		
		if !queued_skill.can_use(current_character):
			print("Cannot use skill - insufficient SP/HP!")
			_cancel_action_target_selection()
			return
		
		print("Skill can be used! Proceeding with targeting...")
		
		match queued_skill.target_type:
			Skill.TARGETS_TYPES.SELF_TARGET:
				valid_targets = [current_character]
			Skill.TARGETS_TYPES.SINGLE_ENEMY:
				valid_targets = current_enemies if current_character in current_players else current_players
			Skill.TARGETS_TYPES.MULTIPLE_ENEMIES:
				valid_targets = current_enemies if current_character in current_players else current_players
				_auto_select_multiple_targets()
				return
			Skill.TARGETS_TYPES.SINGLE_ALLY:
				valid_targets = current_players if current_character in current_players else current_enemies
				if current_character in valid_targets:  # Remove self from valid targets
					valid_targets.erase(current_character)
			Skill.TARGETS_TYPES.MULTIPLE_ALLIES:
				valid_targets = current_players if current_character in current_players else current_enemies
				_auto_select_multiple_targets()
				return
			Skill.TARGETS_TYPES.ALL_TARGETS:
				valid_targets = current_players + current_enemies
				_auto_select_multiple_targets()
				return
		
		# Filter valid targets based on skill requirements
		print("Filtering valid targets based on skill requirements...")
		var filtered_targets: Array = []
		for target in valid_targets:
			if target is Battler:
				var can_target = current_character.can_target_with_skill(queued_skill, target)
				print("Can target ", target.character_name, ": ", can_target)
				if can_target:
					filtered_targets.append(target)
		print("Filtered targets count: ", filtered_targets.size())
		valid_targets = filtered_targets

	# Check if we have any valid targets
	if valid_targets.is_empty():
		print("No valid targets found for this skill!")
		_cancel_action_target_selection()
		return
	
	# Enable only valid targets
	print("Valid targets found: ", valid_targets.size())
	for target in valid_targets:
		if target is Battler:
			target.is_valid_target = true
			target.is_selectable = true
			print("Enabled target: ", target.character_name)
			print("  - Is valid target: ", target.is_valid_target)
			print("  - Is selectable: ", target.is_selectable)

	# Set initial controller target - prioritize last selected target
	if valid_targets.size() > 0:
		var initial_target = valid_targets[0]
		
		# If we have a last selected target and it's still valid, use it
		if last_selected_target and last_selected_target in valid_targets:
			initial_target = last_selected_target
			keyboard_target_index = valid_targets.find(last_selected_target)
		else:
			keyboard_target_index = 0
		
		# Clear all targets first, then set ONLY the default target
		for battler in valid_targets:
			if battler is Battler:
				battler.deselect_as_target()
		
		current_controller_target = initial_target
		current_default_selector = current_controller_target
		current_controller_target.set_as_default_target()
		
		print("Default target set to: ", current_controller_target.character_name)
	
	SignalBus.allow_select_target.emit(true)
	print("=== Target Selection Complete ===\n")

# Helper function for multiple target selection
func _auto_select_multiple_targets() -> void:
	for target in valid_targets:
		if target is Battler:
			target.is_valid_target = true
			target.is_selectable = true
			target.is_targeted = true
	if valid_targets.size() > 0 and valid_targets[0] is Battler:
		current_target = valid_targets[0]
		_use_action_on_target()

# Enhanced controller input handling with better visual feedback
func _unhandled_input(event: InputEvent) -> void:
	if !in_target_selection or valid_targets.is_empty():
		return
		
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		_cycle_controller_target(1 if event.is_action_pressed("ui_right") else -1)
	elif event.is_action_pressed("ui_accept"):
		if current_controller_target:
			current_target = current_controller_target
			_use_action_on_target()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_action_target_selection()

func _cycle_controller_target(direction: int) -> void:
	# Clear ALL targets' selection states first - only ONE highlight allowed
	for battler in valid_targets:
		if battler is Battler:
			battler.deselect_as_target()
	
	# Calculate new index with proper wrapping
	keyboard_target_index += direction
	if keyboard_target_index >= valid_targets.size():
		keyboard_target_index = 0
	elif keyboard_target_index < 0:
		keyboard_target_index = valid_targets.size() - 1
	
	# Set new keyboard target
	if valid_targets.size() > 0 and valid_targets[keyboard_target_index] is Battler:
		current_controller_target = valid_targets[keyboard_target_index]
		current_default_selector = current_controller_target
		current_controller_target.set_as_keyboard_target()
		
		print("Keyboard navigation: Selected ", current_controller_target.character_name)
		print("Current keyboard index: ", keyboard_target_index)
		print("Valid targets size: ", valid_targets.size())

func _cancel_action_target_selection() -> void:
	print("Cancelling target selection")
	in_target_selection = false
	current_target = null
	current_controller_target = null
	current_default_selector = null
	keyboard_target_index = 0
	valid_targets.clear()
	
	# Clear queued action variables
	queued_action = ""
	queued_skill = null
	queued_item = null
	
	# Clear all targeting states for all battlers
	for battler in get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies"):
		if battler is Battler:
			battler.clear_all_selections()
			# Reset to default selectable state
			battler.is_valid_target = true
			battler.is_selectable = true
	
	if in_menu_selection:
		_do_menu_selection()
	else:
		hud.show_action_buttons(current_character)
	SignalBus.allow_select_target.emit(false)

func _cancel_menu_selection() -> void:
	in_menu_selection = false
	hud.item_select.hide()
	hud.skill_select.hide()
	hud.show_action_buttons(current_character)

func _do_menu_selection() -> void:
	in_menu_selection = true
	hud.hide_action_buttons()

# Modify _use_action_on_target to handle states properly
func _use_action_on_target() -> void:
	print("=== USING ACTION ON TARGET ===")
	print("Current target: ", current_target.character_name if current_target else "NULL")
	print("Queued action: ", queued_action)
	print("Queued skill: ", queued_skill.skill_name if queued_skill else "NULL")
	
	in_target_selection = false
	in_menu_selection = false
	is_animating = true
	hud.hide_action_buttons()
	
	match queued_action:
		"skill":
			if queued_skill:
				if queued_skill.effect_type == Skill.EFFECT_TYPE.BUFF:
					# For buff skills, just apply the state without damage
					if queued_skill.applies_state:
						current_target.apply_state(queued_skill.applies_state)
						print("Applied %s state to %s" % [queued_skill.applies_state.state_name, current_target.character_name])
				else:
					# Normal skill handling with damage
					battler_attacking = true
					print("Using skill on target: ", current_target.character_name)
					current_character.use_skill(queued_skill, current_target)
		"attack":
			battler_attacking = true
			print("Performing attack on target: ", current_target.character_name)
			if current_character.default_attack:
				current_character.use_skill(current_character.default_attack, current_target)
			else:
				current_character.attack_anim(current_target)
		"item":
			print("Using item on target: ", current_target.character_name)
			current_character.battle_item(queued_item, current_target)
	
	queued_action = ""
	queued_skill = null
	queued_item = null
	SignalBus.allow_select_target.emit(false)
	end_turn()

func _on_anim_damage():
	print("=== ANIMATION DAMAGE DEBUG ===")
	print("Current character: ", current_character.character_name if current_character else "NULL")
	print("Current target: ", current_target.character_name if current_target else "NULL")
	print("MANAGER: Processing animation damage")
	if current_character and current_target:
		var damage = current_character.get_attack_damage(current_target) # Get damage for current target
		print("Calculated damage: ", damage, " for target: ", current_target.character_name)
		damage_calculation(current_character, current_target, damage)

func process_exp_gain(user, target):
	if not target:
		return
	var exp_gained = target.get_exp_stat().get_exp_on_kill()
	user.get_exp_stat().add_exp(exp_gained)
	user.gain_experience(exp_gained)

# Updating this just to follow pattern being used in battler_enemy
func perform_attack(attacker:Battler, target:Battler):
	current_target = target
	if attacker.default_attack:
		attacker.use_skill(attacker.default_attack, target)
	else:
		attacker.attack_anim(target)

func perform_defend(character):
	character.defend()
	print("%s is defending!" % character.character_name)

# Don't forget that game's also allow skill's to heal players, So use a universal term and if statements.
func perform_skill(user:Battler, target:Battler, skill:Skill) -> void:
	if not skill.can_use(user):
		print("Not enough SP/HP to use skill!")
		return
	
	user.use_skill(skill, target)
	update_hud()

func perform_item(user):
	var amount = user.skill_heal()
	heal_calculation(user, user, amount)

# Loving the additions of formula's!
func damage_calculation(attacker, target, damage):
	damage = Formulas.physical_damage(attacker, target, damage)
	print("%s attacks %s for %d damage!" % [attacker.character_name, target.character_name, damage])
	target.take_damage(damage)
	hud.update_health_bars()
	update_hud()

func heal_calculation(user, target, amount):
	var healing = target.take_healing(amount)
	print("%s heals %s for %d health!" % [user.character_name, target.character_name, healing])
	hud.update_health_bars()  # Add this line
	update_hud()

func enemy_turn(character:Battler) -> void:
	print("=== ENEMY TURN ===")
	print("Enemy character: ", character.character_name)
	
	# Get all players (allies) as targets for enemies
	var available_targets: Array = []
	for node in get_tree().get_nodes_in_group("players"):
		if node is Battler and !node.is_defeated():
			available_targets.append(node)
	
	print("Available targets for enemy: ", available_targets.size())
	for target in available_targets:
		if target is Battler:
			print("  - ", target.character_name, " (HP: ", target.current_health, "/", target.max_health, ")")
	
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	AIManager.choose_action(character, available_targets, all_enemies, self)
	update_hud()
	end_turn()

var battler_attacking:bool = false
func end_turn():
	if skip_turn:
		current_turn = (current_turn + 1) % turn_order.size()
		is_animating = false
		start_next_turn()
	else:
		if battler_attacking:
			await current_battler.wait_attack()
			battler_attacking = false
			
		# Process states before SP regen
		current_battler.process_states()
		current_battler.regenerate_sp()
		
		# Clear targeting states
		print("DEBUG: enemies array before end_turn clear: ", enemies)
		for battler in get_tree().get_nodes_in_group("players") + get_tree().get_nodes_in_group("enemies"):
			battler.is_valid_target = false
			battler.is_selectable = false
			battler.is_targeted = false
			battler.is_default_target = false
			battler.mouse_hover = false
		print("DEBUG: enemies array after end_turn clear: ", enemies)
		
		current_turn = (current_turn + 1) % turn_order.size()
		is_animating = false
		start_next_turn()

func update_hud():
	hud.update_character_info()
	if turn_order[current_turn] in players and not is_animating:
		hud.show_action_buttons(turn_order[current_turn])
	else:
		hud.hide_action_buttons()

func is_battle_over():
	return all_defeated(players) or all_defeated(enemies)

func all_defeated(characters: Array):
	for character in characters:
		if not character.is_defeated():
			return false
	return true

func escape_battle():
	var base_escape_chance = 70
	
	# Reduce chance by 10% for each additional ally
	var ally_penalty = (battle_settings.ally_party - 1) * 10
	
	# Calculate final threshold (base - penalties + difficulty mod)
	var escape_threshold = base_escape_chance - ally_penalty
	
	# Generate random number 1-100
	var roll = randi_range(1, 100)
	
	# Check if escape successful
	if roll <= escape_threshold:
		print("Escape successful! (Rolled %d, needed %d or less)" % [roll, escape_threshold])
		end_battle(BattleEndCondition.ESCAPE) # Use your existing escape scene transition
		return true
	else:
		print("Escape failed! (Rolled %d, needed %d or less)" % [roll, escape_threshold])
		skip_turn = true
		end_turn() # Enemy gets a turn after failed escape
		return false

func end_battle(state: BattleEndCondition = BattleEndCondition.WIN):
	# ESCAPE always ends the battle abruptly. WIN, Will end the battle and return to normal, DEFEAT will end the battle with game over.
	match state:
		BattleEndCondition.ESCAPE:
			print("cutscene will play.")
			pass
		BattleEndCondition.WIN:
			hud.show_battle_result("Victory! All enemies have been defeated.")
			for player in players:
				player.gain_experience(100)
			for enemy in enemies:
				enemy.queue_free()
				# Be sure to toggle Enemy's off on the scene you left.
				get_tree().change_scene_to_file(game_map)
		BattleEndCondition.DEFEAT:
			hud.show_battle_result("Game Over. All players have been defeated.")
			hud.hide_action_buttons()

func update_button_states():
	ActionButtons.get_node("Attack").disabled = not attack_toggle
	ActionButtons.get_node("Skills").disabled = not skills_toggle
	ActionButtons.get_node("Defend").disabled = not defend_toggle
	ActionButtons.get_node("Items").disabled = not item_toggle
	ActionButtons.get_node("Skills").disabled = not run_toggle

func _apply_action_effects(target: Battler) -> void:
	match queued_action:
		"attack":
			if current_character.default_attack:
				current_character.use_skill(current_character.default_attack, target)
			else:
				current_character.attack_anim(target)
		"skill":
			if queued_skill:
				current_character.use_skill(queued_skill, target)
		"item":
			if queued_item:
				current_character.battle_item(queued_item, target)
