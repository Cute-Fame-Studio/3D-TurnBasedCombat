class_name Battler
extends CharacterBody3D

signal anim_damage()
enum TEAM {ALLY, ENEMY}

@export var stats: BattlerStats
@export var inventory: Inventory
@export var default_attack:Skill # Basic attack as a skill
@export_group("Team and AI Controls")
## Define the battler's Team - Allies are Player-controlled
@export var team: TEAM # This will default to ALLY
## If the battler will act independent of player selection, how optimal is it?
## 0 = Randumb, 100 = Big Brain
@export_range(0, 100, 1) var intelligence:int
enum AIType {AGGRESSIVE, DEFENSIVE}
## If this battler acts on its own, what is its strategy/approach to combat?
## Interacts with intelligence to make "optimal" decision.
@export var ai_type:AIType

var character_name: String
var max_health: int
var attack: int
var defense: int
var agility: int

var current_health: int
var current_sp: int = 100  # Add SP variables
var max_sp: int = 100      # Add max SP
var is_defending: bool = false
var current_target = null

# Targeting controls
@onready var material:Material = %Alpha_Surface.material_override
@onready var select_outline:Shader = preload("res://assets/shaders/battler_select_shader.gdshader")
var is_selectable: bool = false:
	set(value):
		is_selectable = value
		if !is_selectable:
			is_targeted = false
			material.next_pass = null
		_update_highlight()

var is_targeted: bool = false:
	set(value):
		is_targeted = value
		_update_highlight()

var mouse_hover: bool = false:
	set(value):
		mouse_hover = value
		_update_highlight()

var is_valid_target: bool = false
var is_default_target: bool = false

func _update_highlight() -> void:
	if !is_selectable or !is_valid_target:
		material.next_pass = null
		return
		
	if is_targeted or (mouse_hover and is_selectable) or is_default_target:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = select_outline
		shader_mat.set_shader_parameter("color", Color.YELLOW)
		shader_mat.set_shader_parameter("thickness", 0.02)
		# Different alpha values for different states
		var alpha = 1.0
		if is_targeted:
			alpha = 1.0  # Fully opaque when selected
		elif mouse_hover:
			alpha = 0.8  # Slightly transparent when hovered
		elif is_default_target:
			alpha = 0.6  # More transparent for default target
		shader_mat.set_shader_parameter("alpha", alpha)
		material.next_pass = shader_mat
	else:
		material.next_pass = null

@export_group("Special Dependencies")
@onready var basic_attack_animation = "attack"
@onready var state_machine = $AnimationTree["parameters/playback"]
@export var skill_node: SkillList
@onready var skill_list: Array[Skill] = []
@onready var exp_node: Experience = get_node("Experience")
@export var damage_indicator_subviewport:SubViewport

func _ready():	
	SignalBus.select_target.connect(check_select_target)
	SignalBus.allow_select_target.connect(set_selectable)
	SignalBus.hover_target.connect(check_hover_target)
	SignalBus.clear_default_selection.connect(_clear_default_selection)
	if !default_attack:
		default_attack = load("res://database/skills/normal_attack.tres")
	
	# If all battlers use the same material, or if there are duplicate battlers of the same type
	# this ensures that they have uniquely assigned materials so the shader does not apply
	# to ALL of them
	var dupe_mat:Material = material.duplicate()
	%Alpha_Surface.material_override = dupe_mat
	material = %Alpha_Surface.material_override
	
	if stats:
		# Basic stats
		character_name = stats.character_name
		%BattlerNameLabel.text = character_name
		
		max_health = stats.max_health
		current_health = max_health
		%BattlerHealthBar.max_value = max_health
		%BattlerHealthBar.value = current_health
		
		attack = stats.attack
		defense = stats.defense
		agility = stats.agility
		
		# SP stats
		max_sp = stats.max_sp
		current_sp = max_sp
		
		if skill_node:
			var updated_skill_list:Array[Skill] = skill_node.get_skills()
			for skill in updated_skill_list:
				if skill is Skill and !skill_list.has(skill):
					skill_list.append(skill)
		
		if default_attack:
			skill_list.append(default_attack)
	else:
		push_error("BattlerStats resource not set!")
	
	# Assign to group based on team
	if team == TEAM.ENEMY:
		add_to_group("enemies")
	elif team == TEAM.ALLY:
		add_to_group("players")
	print("Current Element: ", stats.element)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Select") and is_selectable and mouse_hover:
		select_target()
	elif event is InputEventScreenTouch and event.pressed and is_valid_target:
		# For touchscreen devices, treat touch as hover
		has_hover(true)
	elif event is InputEventScreenTouch and !event.pressed:
		# Touch release
		has_hover(false)

func _mouse_enter() -> void: 
	if is_valid_target:
		has_hover(true)
func _mouse_exit() -> void: 
	has_hover(false)
func has_hover(hover:bool = false) -> void:
	# Only allow hover if this battler is a valid target
	if hover and !is_valid_target:
		return
	mouse_hover = hover
	
	# Emit hover signal when hovering over a valid target
	if hover and is_valid_target:
		SignalBus.hover_target.emit(self)

func set_selectable(can_target: bool) -> void:
	# Don't override is_valid_target here - that's set by BattleManager based on skill requirements
	is_selectable = can_target and is_valid_target
	
	if !is_selectable:
		is_targeted = false
		material.next_pass = null
	_update_highlight()

func check_select_target(target:Battler) -> void:
	if target != self and is_targeted:
		deselect_as_target()

func check_hover_target(target:Battler) -> void:
	# Emit signal to clear all default selections
	SignalBus.clear_default_selection.emit()

func _clear_default_selection() -> void:
	# Clear this battler's default selection if it has one
	if is_default_target:
		is_default_target = false
		_update_highlight()

func select_target() -> void:
	# Will probably want to also add logic that prevents selecting invalid targets
	is_targeted = true
	SignalBus.select_target.emit(self)

func deselect_as_target() -> void:
	is_targeted = false

func set_as_default_target() -> void:
	is_default_target = true
	is_targeted = true


func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage(target) -> int:
	print("PLAYER: calculating damage for target: ", target.name)
	var damage = attack + randi() % 5
	return Formulas.physical_damage(self, target, damage)

@onready var floating_damage_num:PackedScene = preload("res://battle-manager/damage_number.tscn")
func take_damage(amount: int, attacker: Battler = null) -> void:
	var damage_reduction = defense
	if is_defending:
		damage_reduction *= 2
		is_defending = false
	
	var damage_num: DamageNumber = floating_damage_num.instantiate()
	var damage_taken = max(0, amount - damage_reduction)
	damage_num.value = damage_taken
	damage_indicator_subviewport.add_child(damage_num)
	current_health -= damage_taken
	%BattlerHealthBar.value = current_health
	if current_health < 0:
		current_health = 0
	
	print("%s took %d damage. Health: %d/%d" % [character_name, damage_taken, current_health, max_health])
	
	# Handle counter if we have the state
	if attacker and !attacker.is_defeated():
		for state in active_states.values():
			if state is CounterState:
				state.perform_counter(self, attacker)
				break

func take_healing(amount: int):
	var healing = min(amount, max_health - current_health)

	current_health += healing
	%BattlerHealthBar.value = current_health
	print("%s received %d healing. Health: %d/%d" % [character_name, healing, current_health, max_health])
	return healing

func defend():
	is_defending = true
	print("%s is defending. Defense doubled for the next attack." % character_name)

func gain_experience(amount: int):
	print("%s gained %d experience!" % [character_name, amount])
	print("%s needs %d to level up!" % [character_name, get_exp_stat().get_exp_to_level()])

func battle_run():
	pass

func battle_item(item:Item, target:Battler) -> void:
	# TODO: Check if user can legally use this item/take this action
	if inventory.remove_item_from_collection(item) == Inventory.Resolution.SUCCESS:
		ItemHandler.use_item(item, target)
	# Integrate a simple inventory system. Trying to do this alone may cause mistakes.

func battle_idle():
	state_machine.travel("battle_idle")

func attack_anim(target) -> int:
	print("PLAYER: Starting attack for target: ", target.name)
	current_target = target
	state_machine.travel("attack")
	return 0 # Don't return damage here, handled by animation
	#return get_attack_damage(target) # Needing to transfer to dealing damage through animation. Not after! 
	# Some animations may do damage multiple times during their attack, It is better to dynamically show the damage being dealt.

#func deal_damage():
	#return get_attack_damage(target)

func use_skill(skill:Skill, target) -> int:
	if skill.can_use(self):
		state_machine.travel(skill.animation_name)
		skill.apply_costs(self)
		
		match skill.effect_type:
			"Damage":
				return Formulas.calculate_damage(self, target, skill)
			"Heal":
				return skill.base_power
			_:
				return 0
	return 0

func wait_attack():
	if self.is_defending:
		return
	await $AnimationTree.animation_finished
	battle_idle()

func get_exp_stat():
	return exp_node

# # #
# Call methods
# # #
func call_attack():
	print("PLAYER: Animation hit point reached")
	anim_damage.emit()

# # #
# Save System
# # #
func on_save_game(save_data):
	var new_data = BattlerData.new()
	new_data.current_health = current_health  # Using consistent property name
	new_data.current_sp = current_sp
	new_data.current_exp = get_exp_stat().get_total_exp()
	new_data.current_level = get_exp_stat().get_current_level()
	new_data.skill_list = skill_list
	
	save_data["charNameOrID"] = new_data

func on_load_game(load_data):
	var save_data = load_data["charNameOrID"] as BattlerData
	if save_data == null: 
		print("Battler data is empty.")
		return
	
	current_health = save_data.current_health  # Using consistent property name
	current_sp = save_data.current_sp
	get_exp_stat().exp_total = save_data.current_exp
	get_exp_stat().char_level = save_data.current_level
	skill_node.character_skills = save_data.skill_list

func regenerate_sp():
	if stats and current_sp < max_sp:
		var regen_amount = stats.sp_regen
		current_sp = min(current_sp + regen_amount, max_sp)
		print("%s recovered %d SP. SP: %d/%d" % [character_name, regen_amount, current_sp, max_sp])
		
var active_states: Dictionary = {}  # {state_name: State}

# And add these helper functions for state management
func apply_state(state: State) -> void:
	if state == null:
		return
	active_states[state.state_name] = state.duplicate()
	print("[STATE] %s was afflicted with %s!" % [character_name, state.state_name])

func remove_state(state_name: String) -> void:
	if active_states.has(state_name):
		active_states.erase(state_name)
		print("[STATE] %s is no longer affected by %s" % [character_name, state_name])

func process_states() -> void:
	var states_to_remove = []
	
	for state_name in active_states:
		var state = active_states[state_name]
		
		# Handle DOT/HOT effects
		if state.damage_per_turn != 0:
			take_damage(state.damage_per_turn)
		
		# Handle duration
		if state.turns_active > 0:
			state.turns_active -= 1
			if state.turns_active <= 0:
				states_to_remove.append(state_name)
	
	# Remove expired states
	for state_name in states_to_remove:
		remove_state(state_name)
