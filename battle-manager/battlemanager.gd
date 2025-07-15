class_name BattleManager
extends Node3D

enum BattleEndCondition { WIN, DEFEAT, ESCAPE }

var skip_turn = false # Please please please, Change the functionality or entirely remove this down the line.
var players: Array = []
var enemies: Array = []
var turn_order: Array = []
var current_turn: int = 0

var current_character:Battler
var current_target:Battler

@onready var ActionButtons = find_child("ActionButtons")
# For referencing and setting variables in the battle settings.
@onready var battle_settings = GlobalBattleSettings

var current_battler
# Defualt animation should check for weapon's later down the road, And adapt to using them with unique animations.
@export var default_animation = "Locomotion-Library/idle2" # Unused, But i reccomend gettomg the stats and animation from the database.
@export var default_attack:Skill
# Added by repo owner, Fame. To test compatibility with returning after a battle.
@export var game_map = "null"
@onready var hud: BattleHud = $BattleHUD

# Toggles For Battles
@export var Attack_Toggle: bool = true
@export var Skills_Toggle: bool = true
@export var Defend_Toggle: bool = true
@export var Item_Toggle: bool = true
@export var Run_Toggle: bool = true

var defending_players = ["ally_name", "null"]

var is_animating: bool = false

func _ready():
	SignalBus.select_target.connect(target_selected)
	
	if not hud:
		push_error("BattleHUD node not found. Please make sure it's added to the scene.")
		return
	if not hud.is_connected("action_selected", _on_action_selected):
		hud.action_selected.connect(_on_action_selected)
	for player in players:
		if not player.anim_damage.is_connected(_on_anim_damage):
			player.anim_damage.connect(_on_anim_damage)
	initialize_battle()
	# Checking Toggles!
	ActionButtons.get_node("Attack").disabled = not Attack_Toggle
	ActionButtons.get_node("Skills").disabled = not Skills_Toggle
	ActionButtons.get_node("Defend").disabled = not Defend_Toggle
	ActionButtons.get_node("Items").disabled = not Item_Toggle
	ActionButtons.get_node("Run").disabled = not Run_Toggle

func initialize_battle():
	players = get_tree().get_nodes_in_group("players")
	enemies = get_tree().get_nodes_in_group("enemies")
	
	for player:Battler in players:
		print("Have players: ", players)
		hud.on_add_character(player)
		player.battle_idle()
		player.anim_damage.connect(_on_anim_damage)
	
	# Ensure players are at the start of the turn order
	turn_order = players + enemies
	print("Current turn order: ", turn_order)
	
	for enemy:Battler in enemies:
		hud.on_start_combat(enemy)  # Assuming single enemy for now
		enemy.battle_idle()
		enemy.anim_damage.connect(_on_anim_damage)

	start_next_turn()

func count_allies():
	# For now, Should be one.
	battle_settings.ally_party = 1

# See _ready() -> SignalBus.select_target.connect() ... Emitted from Battler
func target_selected(target:Battler) -> void:
	# Will want special handling so the player cannot just select an enemy and
	# override the current enemy's target on their turn
	current_target = target
	hud.enemy = target

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

func _on_action_selected(action: String, target:Battler, skill:Skill):
	#print("Action selected: ", action, " Target: ", target.name if target else "None")
	current_character = turn_order[current_turn]
	current_target = target
	print("Current character: ", current_character.name)
	is_animating = true
	hud.hide_action_buttons()
	
	match action:
		"attack":
			# Consider using default_attack skill instead
			if current_character.default_attack:
				current_character.use_skill(current_character.default_attack, target)
			else:
				current_character.attack_anim(target)
		"defend":
			current_character.defend()
		"skill":  # Changed from "skills"
			if skill:
				current_character.use_skill(skill, target)
		"item":
			current_character.battle_item()
		"run":
			escape_battle()
	
	end_turn()

func _on_anim_damage():
	print("MANAGER: Processing animation damage")
	if current_character and current_target:
		var damage = current_character.get_attack_damage(current_target) # Get damage for current target
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
	var all_players = get_tree().get_nodes_in_group("players")
	var valid_targets = all_players.filter(func(p): return not p.is_in_group("enemies"))
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	
	AIManager.choose_action(character, valid_targets, all_enemies, self)
	update_hud()
	end_turn()

func end_turn():
	if skip_turn:
		current_turn = (current_turn + 1) % turn_order.size()
		is_animating = false
		start_next_turn()
	else:
		await current_battler.wait_attack()
		current_battler.regenerate_sp() # Add SP regeneration
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
	ActionButtons.get_node("Attack").disabled = not Attack_Toggle
	ActionButtons.get_node("Skills").disabled = not Skills_Toggle
	ActionButtons.get_node("Defend").disabled = not Defend_Toggle
	ActionButtons.get_node("Items").disabled = not Item_Toggle
	ActionButtons.get_node("Skills").disabled = not Run_Toggle
