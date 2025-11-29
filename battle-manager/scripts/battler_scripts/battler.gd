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

# Walking animation system
var is_walking: bool = false
var walk_target_position: Vector3
var original_position: Vector3

# Per-battler walking settings (override global if set)
@export_group("Walking Settings", "walking")
## Distance at which this battler requires walking to target. -1.0 = use global setting
@export var custom_walking_distance: float = -1.0
## Speed of walking animation for this battler. -1.0 = use global setting  
@export var custom_walking_speed: float = -1.0
## Walking animation name for this battler. Empty = use global setting
@export var custom_walking_animation: String = ""
## Whether this battler requires walking before attacking
@export var requires_walking: bool = true
## 
## CUSTOM WALKING SETTINGS EXPLAINED:
## -1.0 values mean "use the global setting from BattleManager"
## Set positive values to override global settings for this specific battler
## Example: Set custom_walking_distance = 5.0 for a big monster that needs more space
## Example: Set custom_walking_speed = 1.0 for a slow character
## Example: Set custom_walking_animation = "my_walk_anim" for custom animation

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
var is_keyboard_selected: bool = false  # Track if selected via keyboard
var is_mouse_selected: bool = false    # Track if selected via mouse

func _update_highlight() -> void:
	if !is_selectable or !is_valid_target:
		material.next_pass = null
		return
		
	# Clear any existing highlight first
	material.next_pass = null
	
	# Mouse hover takes priority over everything else
	if mouse_hover and is_selectable:
		# White hover outline (highest priority)
		var hover_mat = ShaderMaterial.new()
		hover_mat.shader = select_outline
		hover_mat.set_shader_parameter("color", Color.WHITE)
		hover_mat.set_shader_parameter("thickness", 0.02)
		hover_mat.set_shader_parameter("alpha", 0.6)
		material.next_pass = hover_mat
	elif is_targeted or is_mouse_selected or is_keyboard_selected or is_default_target:
		# Main selection outline (cyan for all input methods)
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = select_outline
		shader_mat.set_shader_parameter("color", Color.CYAN)
		shader_mat.set_shader_parameter("thickness", 0.025)
		shader_mat.set_shader_parameter("alpha", 1.0)
		material.next_pass = shader_mat
		
		# Add debug info to confirm which battler is highlighted
		print("Highlighting battler: ", character_name, " with cyan outline")

@export_group("Special Dependencies")
@onready var basic_attack_animation = "attack"
@onready var state_machine = $AnimationTree["parameters/playback"]
@export var skill_node: SkillList
@onready var skill_list: Array[Skill] = []
@onready var exp_node: Experience = get_node("Experience")
@export var damage_indicator_subviewport:SubViewport
@onready var anim_tree: AnimationTree = $AnimationTree

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
	
	# Set up animation parameters
	anim_tree.set("parameters/conditions/is_turning_right", false)
	anim_tree.set("parameters/conditions/is_turning_left", false)

func _input(event: InputEvent) -> void:
	# Check if mouse input is enabled in battle manager
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and not battle_manager.mouse_input_toggle:
		return
		
	if event.is_action_pressed("Select") and is_selectable and is_valid_target:
		print("=== MOUSE INPUT DEBUG ===")
		print("Battler: ", character_name)
		print("Event: ", event)
		print("Is selectable: ", is_selectable)
		print("Is valid target: ", is_valid_target)
		# Allow selection if valid target, regardless of hover state
		select_target()
	elif event is InputEventScreenTouch and event.pressed and is_valid_target:
		# For touchscreen devices, treat touch as selection
		if is_selectable:
			select_target()
	elif event is InputEventScreenTouch and !event.pressed:
		# Touch release - clear hover state
		has_hover(false)

func _mouse_enter() -> void: 
	# Check if mouse input is enabled in battle manager
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and not battle_manager.mouse_input_toggle:
		return
		
	print("=== MOUSE ENTER DEBUG ===")
	print("Battler: ", character_name)
	print("Is valid target: ", is_valid_target)
	if is_valid_target:
		has_hover(true)
		
func _mouse_exit() -> void: 
	# Check if mouse input is enabled in battle manager
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and not battle_manager.mouse_input_toggle:
		return
		
	print("=== MOUSE EXIT DEBUG ===")
	print("Battler: ", character_name)
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
		clear_all_selections()
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
	print("=== TARGET SELECTION DEBUG ===")
	print("Battler: ", character_name)
	print("Is selectable: ", is_selectable)
	print("Is valid target: ", is_valid_target)
	print("Is targeted: ", is_targeted)
	
	# Will probably want to also add logic that prevents selecting invalid targets
	# Clear all other selection states first
	is_keyboard_selected = false
	is_default_target = false
	is_mouse_selected = true
	is_targeted = true
	print("Emitting select_target signal for: ", character_name)
	SignalBus.select_target.emit(self)

func deselect_as_target() -> void:
	is_targeted = false
	is_mouse_selected = false
	is_keyboard_selected = false
	is_default_target = false
	# Force update the highlight to clear it
	_update_highlight()

func set_as_default_target() -> void:
	# Clear other selection states first
	is_mouse_selected = false
	is_keyboard_selected = false
	is_default_target = true
	is_targeted = true
	# Force update the highlight
	_update_highlight()

func set_as_keyboard_target() -> void:
	# Clear other selection types first
	is_mouse_selected = false
	is_default_target = false
	is_keyboard_selected = true
	is_targeted = true
	# Force update the highlight
	_update_highlight()

func clear_all_selections() -> void:
	is_targeted = false
	is_mouse_selected = false
	is_keyboard_selected = false
	is_default_target = false
	mouse_hover = false
	material.next_pass = null


func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage(target) -> int:
	print("PLAYER: calculating damage for target: ", target.character_name)
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
	
	# Check if this battler is defeated and should be removed
	if current_health <= 0 and team == TEAM.ENEMY:
		var battle_manager = get_tree().get_first_node_in_group("battle_manager")
		if battle_manager and battle_manager.remove_defeated_enemies:
			print("Removing defeated enemy: ", character_name)
			# Remove from turn order
			if battle_manager.turn_order.has(self):
				battle_manager.turn_order.erase(self)
			# Remove from enemies array
			if battle_manager.enemies.has(self):
				battle_manager.enemies.erase(self)
			# Remove from scene
			call_deferred("queue_free")
	
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
	
	# Play defend animation
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var defend_anim = battle_manager.get_animation("defend") if battle_manager else "defend"
	state_machine.travel(defend_anim)

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
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var anim_name = battle_manager.get_animation("idle") if battle_manager else "idle1"
	state_machine.travel(anim_name)

func attack_anim(target) -> int:
	print("PLAYER: Starting attack sequence for target: ", target.character_name)
	current_target = target
	
	# First turn to face walking direction
	await turn_to_face_target(target)
	
	# Start walking if needed
	if await walk_to_target(target):
		print("Walking to target")
		state_machine.travel("walk")  # Changed from "run" to "walk"
		while is_walking:
			await get_tree().create_timer(0.016).timeout
	
	# Turn to face target again after walking (in case target moved)
	await turn_to_face_target(target)
	
	# Now perform the attack
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var attack_anim = battle_manager.get_animation("attack") if battle_manager else "attack"
	state_machine.travel(attack_anim)
	
	return 0

#func deal_damage():
	#return get_attack_damage(target)

func use_skill(skill:Skill, target) -> int:
	if skill.can_use(self):
		# Turn to face target before using skill
		await turn_to_face_target(target)
		
		# Try to walk to target first for damage skills
		if skill.effect_type == Skill.EFFECT_TYPE.DAMAGE and await walk_to_target(target):
			# Wait for walking to complete, then use skill
			await get_tree().create_timer(0.1).timeout
			while is_walking:
				await get_tree().create_timer(0.1).timeout
		
		# Use skill animation name if available, otherwise use attack animation
		var anim_name = skill.animation_name
		if anim_name.is_empty():
			var battle_manager = get_tree().get_first_node_in_group("battle_manager")
			anim_name = battle_manager.get_animation("attack") if battle_manager else "attack"
		
		state_machine.travel(anim_name)
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
	
	# If we walked to attack, wait for return movement to complete
	if original_position != Vector3.ZERO and not is_walking:
		# Start return movement if not already started
		return_to_original_position()
		# Wait for return movement to complete
		while is_walking:
			await get_tree().create_timer(0.1).timeout
	
	battle_idle()

# Turning animation system
var is_turning: bool = false
var turn_target_rotation: float

var is_turning_right: bool = false
var is_turning_left: bool = false

func turn_to_face_target(target: Battler) -> void:
	var direction = target.global_position - global_position
	var target_angle = atan2(direction.x, direction.z)
	var current_angle = rotation.y
	var angle_diff = wrapf(target_angle - current_angle, -PI, PI)
	
	if abs(angle_diff) > 0.1:
		is_turning = true
		turn_target_rotation = target_angle
		
		# Start appropriate turn animation
		if angle_diff > 0:
			state_machine.travel("turn_right")
		else:
			state_machine.travel("turn_left")
		
		# Wait for turn animation to complete
		while is_turning:
			# Smoothly interpolate rotation to match animation
			rotation.y = lerp_angle(rotation.y, turn_target_rotation, 0.1)
			
			if abs(wrapf(rotation.y - turn_target_rotation, -PI, PI)) < 0.05:
				rotation.y = turn_target_rotation
				is_turning = false
				
				# Ensure we transition back to idle through the animation system
				state_machine.travel("idle1")
			
			await get_tree().create_timer(0.016).timeout
	
	await get_tree().create_timer(0.016).timeout

# Walking animation system functions
func walk_to_target(target: Battler) -> bool:
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		print("No battle manager found, skipping walking")
		return false
		
	# Check if walking is enabled globally and for this battler
	if not battle_manager.enable_walking_to_target or not requires_walking:
		return false
		
	# Get walking settings (custom or global)
	var walking_distance = custom_walking_distance if custom_walking_distance > 0 else battle_manager.walking_distance_threshold
	var walking_speed = custom_walking_speed if custom_walking_speed > 0 else battle_manager.walking_speed
	var walking_anim = custom_walking_animation if custom_walking_animation != "" else battle_manager.get_animation("walk")  # Changed from "run" to "walk"
	
	var distance_to_target = global_position.distance_to(target.global_position)
	if distance_to_target <= walking_distance:
		print("Target is close enough, no walking needed")
		return false
	
	# Store original position for return
	original_position = global_position	# Calculate target position (move closer to target)
	var direction = (target.global_position - global_position).normalized()
	walk_target_position = target.global_position - direction * walking_distance
	
	# Start walking animation
	set_walking(true)
	
	# Move towards target
	var tween = create_tween()
	tween.tween_property(self, "global_position", walk_target_position, 
		global_position.distance_to(walk_target_position) / walking_speed)
	tween.tween_callback(_on_walk_complete)
	
	return true

func _try_animation(anim_name: String) -> bool:
	# Try to travel to animation, return false if it fails
	var current_state = state_machine.get_current_node()
	if current_state == anim_name:
		return true
		
	# Try to travel to the animation
	state_machine.travel(anim_name)
	
	# Check if the travel was successful by waiting a frame
	await get_tree().process_frame
	var new_state = state_machine.get_current_node()
	return new_state == anim_name

func _on_walk_complete():
	set_walking(false)
	battle_idle()

func return_to_original_position():
	if is_walking or original_position == Vector3.ZERO:
		return
		
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return
		
	var walking_speed = custom_walking_speed if custom_walking_speed > 0 else battle_manager.walking_speed
	var walking_anim = custom_walking_animation if custom_walking_animation != "" else battle_manager.get_animation("run")
		
	is_walking = true
	if not await _try_animation(walking_anim):
		state_machine.travel("idle1")
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", original_position, 
		global_position.distance_to(original_position) / walking_speed)
	tween.tween_callback(_on_return_complete)

func _on_return_complete():
	is_walking = false
	original_position = Vector3.ZERO
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
		var regen_amount = 5  # Default SP regeneration
		if stats.has_method("get") and stats.get("sp_regen") != null:
			regen_amount = stats.sp_regen
		current_sp = min(current_sp + regen_amount, max_sp)
		print("%s recovered %d SP. SP: %d/%d" % [character_name, regen_amount, current_sp, max_sp])

func can_target_with_skill(skill: Skill, target: Battler) -> bool:
	print("=== CAN TARGET WITH SKILL DEBUG ===")
	print("Skill: ", skill.skill_name)
	print("Target: ", target.character_name)
	print("Target team: ", target.team)
	print("Self team: ", team)
	
	if !skill or !target:
		print("Skill or target is null!")
		return false
	
	# Check if skill can be used (costs)
	if !skill.can_use(self):
		print("Skill cannot be used due to costs!")
		return false
	
	# Check target type compatibility
	match skill.target_type:
		Skill.TARGETS_TYPES.SELF_TARGET:
			var result = target == self
			print("SELF_TARGET check: ", result)
			return result
		Skill.TARGETS_TYPES.SINGLE_ENEMY:
			var result = target.team == TEAM.ENEMY and target != self
			print("SINGLE_ENEMY check: ", result)
			return result
		Skill.TARGETS_TYPES.MULTIPLE_ENEMIES:
			var result = target.team == TEAM.ENEMY and target != self
			print("MULTIPLE_ENEMIES check: ", result)
			return result
		Skill.TARGETS_TYPES.SINGLE_ALLY:
			var result = target.team == TEAM.ALLY and target != self
			print("SINGLE_ALLY check: ", result)
			return result
		Skill.TARGETS_TYPES.MULTIPLE_ALLIES:
			var result = target.team == TEAM.ALLY and target != self
			print("MULTIPLE_ALLIES check: ", result)
			return result
		Skill.TARGETS_TYPES.ALL_TARGETS:
			var result = target != self
			print("ALL_TARGETS check: ", result)
			return result
		_:
			print("Unknown target type!")
			return false
		
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

func set_walking(value: bool):
	is_walking = value
	anim_tree.set("parameters/conditions/is_walking", value)

func set_defending(value: bool):
	is_defending = value
	anim_tree.set("parameters/conditions/is_defending", value)
