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
var is_counter_stunned: bool = false  # Stunned by being hit with a counter attack
var _is_despawning: bool = false

# Walking animation system
var is_advancing: bool = false
var advance_target_position: Vector3
var original_position: Vector3

# Per-battler movement settings (override global if set)
@export_group("Movement Settings", "movement")
## Distance at which this battler requires movement to target. -1.0 = use global setting
@export var custom_movement_distance: float = -1.0
## Speed of movement animation for this battler. -1.0 = use global setting  
@export var custom_movement_speed: float = -1.0
## Movement animation name for this battler. Empty = use global setting
@export var custom_movement_animation: String = ""
## Whether this battler requires movement before attacking
@export var requires_walking: bool = true
## Force movement animation to sync immediately when moving toward positive Z (toward enemy)
@export var sync_movement_animation_forward: bool = true
## Maximum time (seconds) this battler can be stuck in advancing state before auto-return
@export var stuck_movement_timeout: float = 5.0
## If true, fallback damage applies if animation callback doesn't fire
@export var allow_animation_fallback: bool = true
## 
## CUSTOM MOVEMENT SETTINGS EXPLAINED:
## -1.0 values mean "use the global setting from BattleManager"
## Set positive values to override global settings for this specific battler
## Example: Set custom_movement_distance = 5.0 for a big monster that needs more space
## Example: Set custom_movement_speed = 1.0 for a slow character
## Example: Set custom_movement_animation = "my_movement_anim" for custom animation



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

@export_group("Rotation Settings", "rotation")
## Invert rotation direction if character model faces opposite direction (-1 = invert, 1 = normal)
@export var rotation_direction: int = 1
## Whether to face away from target instead of towards (for back-to-back positioning)
@export var face_away_from_target: bool = false

@export_group("Special Dependencies")
@onready var basic_attack_animation = "attack"
@onready var anim_tree: AnimationTree = $AnimationTree
var state_machine: AnimationNodeStateMachinePlayback
@export var skill_node: SkillList
@onready var skill_list: Array[Skill] = []
@onready var exp_node: Experience = get_node("Experience")
@export var damage_indicator_subviewport:SubViewport

@export_group("Counter Stun Settings", "stun")
## Duration (seconds) before recovering from being hit by a counter attack
@export var counter_stun_duration: float = 1.5

# Tracks the current attack animation duration so we can wait for it without
# relying on AnimationPlayer.animation_finished (which AnimationTree blocks).
# Set automatically inside _try_animation when an attack state is travelled to.
var _current_attack_duration: float = 1.0


func _ready():
	# Disconnect any existing connections first
	if SignalBus.select_target.is_connected(check_select_target):
		SignalBus.select_target.disconnect(check_select_target)
	if SignalBus.allow_select_target.is_connected(set_selectable):
		SignalBus.allow_select_target.disconnect(set_selectable)
	if SignalBus.hover_target.is_connected(check_hover_target):
		SignalBus.hover_target.disconnect(check_hover_target)
	if SignalBus.clear_default_selection.is_connected(_clear_default_selection):
		SignalBus.clear_default_selection.disconnect(_clear_default_selection)
	
	# Now connect
	SignalBus.select_target.connect(check_select_target)
	SignalBus.allow_select_target.connect(set_selectable)
	SignalBus.hover_target.connect(check_hover_target)
	SignalBus.clear_default_selection.connect(_clear_default_selection)
	
	state_machine = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	
	# Verify state_machine is valid
	if not state_machine:
		push_error("AnimationNodeStateMachinePlayback not found! Check AnimationTree setup.")
		return
	
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
		
		# Apply level-focused progression (calculates stats based on level)
		apply_level_progression()
		
		%BattlerHealthBar.max_value = max_health
		%BattlerHealthBar.value = current_health
		
		# SP stats
		max_sp = max_sp  # Already set by apply_level_progression
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
		
	if is_valid_target:
		has_hover(true)
		
func _mouse_exit() -> void: 
	# Check if mouse input is enabled in battle manager
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if battle_manager and not battle_manager.mouse_input_toggle:
		return
		
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

func check_hover_target(_target: Battler) -> void:
	SignalBus.clear_default_selection.emit()

func _clear_default_selection() -> void:
	# Clear this battler's default selection if it has one
	if is_default_target:
		is_default_target = false
		_update_highlight()

func select_target() -> void:
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
	
	var damage_taken = max(0, amount - damage_reduction)
	
	# Check for weakness state BEFORE applying damage
	var weakness_multiplier = 1.0
	if active_states.has("Weakness"):
		weakness_multiplier = 1.5  # Takes 50% more damage
		print("[WEAKNESS] %s is afflicted with weakness, damage increased by 50%%" % character_name)
	
	damage_taken = int(float(damage_taken) * weakness_multiplier)
	
	var damage_num: DamageNumber = floating_damage_num.instantiate()
	damage_num.value = damage_taken
	damage_indicator_subviewport.add_child(damage_num)
	current_health -= damage_taken
	%BattlerHealthBar.value = current_health
	if current_health < 0:
		current_health = 0
	
	print("%s took %d damage. Health: %d/%d" % [character_name, damage_taken, current_health, max_health])
	
	# Turn to face attacker after being hit (for visual feedback)
	if attacker:
		await turn_to_face_target(attacker)
	
	# WAKE UP FROM SLEEP WHEN ATTACKED
	if active_states.has("Sleep"):
		remove_state("Sleep")
		print("%s woke up from sleep after being hit!" % character_name)
	
	# TRIGGER COUNTER IF ACTIVE - await so attacker stays in place during counter
	if attacker and active_states.has("Counter"):
		var counter_state = active_states["Counter"] as CounterState
		if counter_state:
			await counter_state.perform_counter(self, attacker)
	
	# Check if this battler is defeated and should be removed
	if current_health <= 0 and team == TEAM.ENEMY:
		if _is_despawning:
			return
		_is_despawning = true
		var battle_manager = get_tree().get_first_node_in_group("battle_manager")
		if battle_manager and battle_manager.has_method("register_enemy_defeat_reward"):
			battle_manager.register_enemy_defeat_reward(self)
		if battle_manager and battle_manager.remove_defeated_enemies:
			print("Removing defeated enemy: ", character_name)
			if battle_manager.turn_order.has(self):
				battle_manager.turn_order.erase(self)
			if battle_manager.enemies.has(self):
				battle_manager.enemies.erase(self)
			await _fade_and_remove()
		else:
			_is_despawning = false

func take_healing(amount: int):
	var healing = min(amount, max_health - current_health)

	current_health += healing
	%BattlerHealthBar.value = current_health
	print("%s received %d healing. Health: %d/%d" % [character_name, healing, current_health, max_health])
	return healing

func defend():
	is_defending = true
	# FORCE use idle1, not the dictionary
	_try_animation("idle1")
	print("%s is defending. Defense doubled for the next attack." % character_name)

## Switch to a different AnimationTree
## Returns true if switch successful, false otherwise
func attack_anim(target) -> void:
	print("PLAYER: Starting attack sequence for target: ", target.character_name)
	
	# SAFETY: Prevent self-attacks
	if target == self:
		print("[Safety] Prevented self-attack on ", character_name)
		return
	
	current_target = target
	
	await turn_to_face_target(target)
	
	if advance_to_target(target):
		_try_animation("walk")
		while is_advancing:
			await get_tree().create_timer(0.016).timeout
	
	await turn_to_face_target(target)
	
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var attack_animation_name = battle_manager.get_animation("attack") if battle_manager else "attack"
	if not _try_animation(attack_animation_name):
		_try_animation("attack")
	
	# Wait for attack animation using duration read from AnimationPlayer at travel time.
	# AnimationTree blocks AnimationPlayer.animation_finished so we use a timer instead.
	await get_tree().create_timer(_current_attack_duration + 0.12).timeout
	
	# CRITICAL: Wait for damage callback and counters to complete before returning
	# Give time for the damage callback signal and counter execution to finish
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	# If stunned by counter, wait before returning to position
	if is_counter_stunned:
		await get_tree().create_timer(counter_stun_duration).timeout
		is_counter_stunned = false
	
	# NOW return to original position after damage/counter completed
	if original_position != Vector3.ZERO:
		return_to_original_position()
		# Wait for return movement to complete
		while is_advancing:
			await get_tree().create_timer(0.1).timeout
	
	# Return to idle state
	battle_idle()

func use_skill(skill:Skill, target) -> void:
	if skill.can_use(self):
		# SAFETY: Prevent self-targeting for damage skills
		if target == self and skill.effect_type == Skill.EFFECT_TYPE.DAMAGE:
			print("[Safety] Prevented self-damage skill on ", character_name)
			return
		
		await turn_to_face_target(target)
		
		# Advance to target for DAMAGE skills and BUFF/DEBUFF skills targeting enemies
		var should_advance = false
		if skill.effect_type == Skill.EFFECT_TYPE.DAMAGE:
			should_advance = true
		elif skill.effect_type == Skill.EFFECT_TYPE.BUFF and target != self and target.team == TEAM.ENEMY:
			# BUFF skills on enemies (debuffs) should advance, but not on allies
			should_advance = true
		
		if should_advance and advance_to_target(target):
			_try_animation("walk")
			await get_tree().create_timer(0.1).timeout
			while is_advancing:
				await get_tree().create_timer(0.016).timeout
		
		var anim_name = skill.animation_name
		# Skills use their own animations, not the global dictionary
		if anim_name.is_empty():
			anim_name = "attack"  # Default to attack for all skill types
		
		if not _try_animation(anim_name):
			# Hard fallback for damage actions: always ensure a real attack state plays.
			if skill.effect_type == Skill.EFFECT_TYPE.DAMAGE:
				_try_animation("attack")
		skill.apply_costs(self)
		
		# Wait for animation using duration read from AnimationPlayer at travel time.
		# AnimationTree blocks AnimationPlayer.animation_finished so we use a timer instead.
		match skill.effect_type:
			Skill.EFFECT_TYPE.DAMAGE:
				# Damage is applied via animation callback (_on_anim_damage)
				await get_tree().create_timer(_current_attack_duration + 0.12).timeout
			Skill.EFFECT_TYPE.HEAL:
				target.take_healing(skill.hp_delta)
				# Apply state if present (healing with state effect)
				if skill.applies_state and randf() * 100 <= skill.state_apply_chance:
					target.apply_state(skill.applies_state)
				await get_tree().create_timer(_current_attack_duration).timeout
			Skill.EFFECT_TYPE.BUFF:
				# State-only skill: just apply the state, no damage
				if skill.applies_state:
					print("Applying state: ", skill.applies_state.state_name, " to ", target.character_name)
					if randf() * 100 <= skill.state_apply_chance:
						target.apply_state(skill.applies_state)
					else:
						print("State application missed! (", skill.state_apply_chance, "% chance)")
				else:
					print("ERROR: BUFF skill has no applies_state set!")
				await get_tree().create_timer(_current_attack_duration).timeout
			_:
				pass
		
		# CRITICAL: Wait for damage callback and counters to complete before returning
		# Give time for the damage callback signal and counter execution to finish
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().create_timer(0.1).timeout
		
		# NOW return to original position after damage/counter completed
		if original_position != Vector3.ZERO:
			return_to_original_position()
			# Wait for return movement to complete
			while is_advancing:
				await get_tree().create_timer(0.1).timeout
		
		# Return to idle state
		battle_idle()

func wait_attack():
	if self.is_defending:
		return
	# Wait for attack animation using duration read from AnimationPlayer at travel time
	await get_tree().create_timer(_current_attack_duration).timeout
	
	# If we advanced to attack, return to original position
	if original_position != Vector3.ZERO:
		return_to_original_position()
		# Wait for return movement to complete
		while is_advancing:
			await get_tree().create_timer(0.1).timeout
	
	# Always end in idle state
	battle_idle()

func battle_idle():
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var anim_name = battle_manager.get_animation("idle") if battle_manager else "idle1"
	_try_animation(anim_name)
	# Clear any lingering animation conditions
	anim_tree.set("parameters/conditions/is_walking", false)
	anim_tree.set("parameters/conditions/is_turning", false)
	anim_tree.set("parameters/conditions/is_attacking", false)

# Turning animation system
var is_turning: bool = false
var turn_target_rotation: float

var is_turning_right: bool = false
var is_turning_left: bool = false

func turn_to_face_target(target: Battler) -> void:
	if not target:
		return
	
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	var speed_mult = battle_manager.speed_multiplier if battle_manager else 1.0
	
	var direction = (target.global_position - global_position).normalized()
	if face_away_from_target:
		direction = -direction
	
	var target_angle = atan2(direction.x * rotation_direction, direction.z)
	var current_angle = atan2(global_transform.basis.z.x, global_transform.basis.z.z)
	var angle_diff = angle_difference(current_angle, target_angle)
	
	# If angle difference is small enough, just rotate directly
	if abs(angle_diff) < 0.1:
		var new_basis = global_transform.basis
		new_basis = new_basis.rotated(Vector3.UP, angle_diff)
		global_transform.basis = new_basis
		return
	
	# Otherwise use animation
	is_turning = true
	if angle_diff > 0:
		anim_tree.set("parameters/conditions/is_turning_right", true)
		anim_tree.set("parameters/conditions/is_turning_left", false)
	else:
		anim_tree.set("parameters/conditions/is_turning_left", true)
		anim_tree.set("parameters/conditions/is_turning_right", false)
	
	await get_tree().create_timer(0.3 / speed_mult).timeout
	
	anim_tree.set("parameters/conditions/is_turning_right", false)
	anim_tree.set("parameters/conditions/is_turning_left", false)
	
	var final_basis = global_transform.basis
	final_basis = final_basis.rotated(Vector3.UP, angle_diff)
	global_transform.basis = final_basis
	
	is_turning = false

func angle_difference(from: float, to: float) -> float:
	var diff = fmod(to - from + PI, TAU) - PI
	return diff

func advance_to_target(target: Battler) -> bool:
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return false
		
	if not battle_manager.enable_movement_to_target or not requires_walking:
		return false
	
	# SAFETY: Prevent overlapping advances
	if is_advancing:
		print("[Safety] Movement already in progress on ", character_name)
		return false
		
	var movement_distance = custom_movement_distance if custom_movement_distance > 0 else battle_manager.movement_distance_threshold
	var movement_speed = custom_movement_speed if custom_movement_speed > 0 else battle_manager.movement_speed
	
	# Apply speed multiplier from battle manager
	movement_speed *= battle_manager.speed_multiplier
	
	var distance_to_target = global_position.distance_to(target.global_position)
	if distance_to_target <= movement_distance:
		return false
	
	original_position = global_position
	var direction = (target.global_position - global_position).normalized()
	advance_target_position = target.global_position - direction * movement_distance
	
	print("[WALK DEBUG] %s advancing toward %s - setting is_walking=true, direction=%v" % [character_name, target.character_name, direction])
	
	set_advancing(true)
	var tween = create_tween()
	tween.set_speed_scale(battle_manager.speed_multiplier)
	tween.tween_property(self, "global_position", advance_target_position, 
		global_position.distance_to(advance_target_position) / movement_speed)
	tween.tween_callback(_on_advance_complete)
	
	# Start movement timeout timer
	_start_movement_timeout()
	
	return true

## Attempts to travel to an animation state by name.
## For attack states inside the basic_attacks sub-machine, travels to the sub-machine
## first then to the specific state. Also reads the animation duration from AnimationPlayer
## and stores it in _current_attack_duration so callers can await the correct length.
func _try_animation(anim_name: String) -> bool:
	if not anim_name or anim_name.is_empty():
		return false
	if not state_machine:
		return false

	# Route attacks through the nested state machine using two-step travel.
	# Parent playback cannot travel directly into child paths in Godot.
	var attack_states = ["attack", "kick", "skill-strong-attack"]
	var attack_leaf = anim_name
	if anim_name in attack_states:
		attack_leaf = anim_name
	elif anim_name.begins_with("basic_attacks/"):
		attack_leaf = anim_name.get_slice("/", 1)

	if attack_leaf in attack_states:
		state_machine.travel("basic_attacks")
		var attacks_sm = anim_tree.get("parameters/basic_attacks/playback") as AnimationNodeStateMachinePlayback
		if attacks_sm:
			attacks_sm.travel(attack_leaf)
		else:
			push_warning("Missing nested playback for basic_attacks on %s" % character_name)
			return false
		# Read actual animation length from AnimationPlayer so waiters use the correct duration.
		# AnimationTree blocks animation_finished from firing so we wait by timer instead.
		_current_attack_duration = max(0.25, _get_animation_duration(attack_leaf))
	else:
		state_machine.travel(anim_name)

	return true

## Looks up the length of an animation from AnimationPlayer by state name.
## Searches all animation libraries if a direct match is not found.
## Returns 1.0 as a safe fallback if the animation cannot be found.
func _get_animation_duration(anim_name: String) -> float:
	var anim_player = get_node_or_null("AnimationPlayer")
	if not anim_player:
		return 1.0
	
	# Resolve state name -> actual animation clip name from AnimationTree state machine.
	# Example: "attack" state may map to "Locomotion-Library/attack1".
	var resolved_name = _resolve_state_animation_name(anim_name)
	if not resolved_name.is_empty() and anim_player.has_animation(resolved_name):
		return anim_player.get_animation(resolved_name).length
	
	# Try direct name match first
	if anim_player.has_animation(anim_name):
		return anim_player.get_animation(anim_name).length
	# Search all libraries for an animation whose short name matches
	for lib_name in anim_player.get_animation_library_list():
		var lib = anim_player.get_animation_library(lib_name)
		for anim in lib.get_animation_list():
			if anim == anim_name:
				var full_name = (lib_name + "/" + anim) if lib_name != "" else anim
				return anim_player.get_animation(full_name).length
	return 1.0  # Fallback if animation not found

## Resolves a state machine state name to the animation clip assigned in that state.
## Returns empty string if the state is not an AnimationNodeAnimation.
func _resolve_state_animation_name(state_name: String) -> String:
	if not anim_tree:
		return ""
	var root_sm = anim_tree.tree_root as AnimationNodeStateMachine
	if not root_sm:
		return ""
	
	# Attack states live inside the nested basic_attacks sub-machine.
	var attack_states = ["attack", "kick", "skill-strong-attack"]
	var leaf_state = state_name.get_slice("/", 1) if state_name.begins_with("basic_attacks/") else state_name
	if leaf_state in attack_states:
		if root_sm.has_node("basic_attacks"):
			var attack_sm = root_sm.get_node("basic_attacks") as AnimationNodeStateMachine
			if attack_sm and attack_sm.has_node(leaf_state):
				var attack_node = attack_sm.get_node(leaf_state) as AnimationNodeAnimation
				if attack_node and str(attack_node.animation) != "":
					return str(attack_node.animation)
	
	# Top-level states
	if root_sm.has_node(state_name):
		var node = root_sm.get_node(state_name) as AnimationNodeAnimation
		if node and str(node.animation) != "":
			return str(node.animation)
	
	return ""

func _on_advance_complete():
	set_advancing(false)
	# NOTE: Do NOT travel to idle1 here - it fights whatever the caller triggers next
	print("Movement completed, is_advancing set to false")

## Start movement timeout to prevent stuck advancing state
func _start_movement_timeout() -> void:
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return
	
	var timeout = stuck_movement_timeout
	print("[Movement Timeout] Started (%.1fs) on %s" % [timeout, character_name])
	
	await get_tree().create_timer(timeout / battle_manager.speed_multiplier).timeout
	
	# Check if still advancing (means it got stuck)
	if is_advancing:
		print("[Movement Timeout] WARNING: Movement stuck on %s! Force-returning." % character_name)
		set_advancing(false)
		return_to_original_position()

func return_to_original_position():
	if is_advancing or original_position == Vector3.ZERO:
		return
		
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return
		
	var movement_speed = custom_movement_speed if custom_movement_speed > 0 else battle_manager.movement_speed
	movement_speed *= battle_manager.speed_multiplier
	
	set_advancing(true)
	_try_animation("walk")
	
	var tween = create_tween()
	tween.set_speed_scale(battle_manager.speed_multiplier)
	tween.tween_property(self, "global_position", original_position, 
		global_position.distance_to(original_position) / movement_speed)
	tween.tween_callback(_on_return_complete)

func _on_return_complete():
	set_advancing(false)
	_try_animation("idle1")
	
func get_exp_stat():
	return exp_node

# # #
# Animation Damage & Effects Application
# # #
## Called when animation reaches the hit point - applies damage and any attached states
func apply_animation_effects():
	print("PLAYER: Animation hit point reached")
	anim_damage.emit()

func call_attack():
	# Deprecated - use apply_animation_effects() instead
	apply_animation_effects()

# In take_damage, add state application for counter:

# Update the animation callback to use new name:
func _on_anim_damage():
	var battle_manager = get_tree().get_first_node_in_group("battle_manager")
	if not battle_manager:
		return
	
	# ONLY process damage for attack and skill actions
	# AND only if we haven't already processed this action
	if battle_manager.current_character and battle_manager.current_target and battle_manager.queued_action in ["attack", "skill"]:
		var damage = battle_manager.current_character.get_attack_damage(battle_manager.current_target)
		battle_manager.damage_calculation(battle_manager.current_character, battle_manager.current_target, damage)
		# IMMEDIATELY clear queued action to prevent double processing
		battle_manager.queued_action = ""

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
		var regen_amount = 5
		if stats.has_method("get") and stats.get("sp_regen") != null:
			regen_amount = stats.sp_regen
		# Add randomness to SP gains (±30% variation)
		var randomness = randf_range(0.7, 1.3)
		regen_amount = int(float(regen_amount) * randomness)
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
	var state_copy = state.duplicate()
	# Force state_name to be set properly after duplication
	state_copy.state_name = state.state_name
	var key = state_copy.state_name
	active_states[key] = state_copy
	print("[STATE] %s was afflicted with %s!" % [character_name, key])

func remove_state(state_name: String) -> void:
	if active_states.has(state_name):
		active_states.erase(state_name)
		print("[STATE] %s is no longer affected by %s" % [character_name, state_name])

func process_states() -> void:
	var states_to_remove = []
	
	for state_name in active_states:
		var state = active_states[state_name]
		
		# Handle DOT/HOT effects with damage multiplier based on target defense
		if state.damage_per_turn != 0:
			# Apply power multiplier and defense reduction: base_damage * power_mult * (1 - (defense / 100))
			var defense_multiplier = max(0.1, 1.0 - (float(defense) / 100.0))
			var actual_damage = int(state.damage_per_turn * state.power_multiplier * defense_multiplier)
			actual_damage = max(1, actual_damage)  # Minimum 1 damage
			
			# Only show damage popup for positive damage (DOT)
			if actual_damage > 0:
				var damage_num: DamageNumber = floating_damage_num.instantiate()
				damage_num.value = actual_damage
				damage_indicator_subviewport.add_child(damage_num)
				current_health -= actual_damage
				%BattlerHealthBar.value = current_health
				if current_health < 0:
					current_health = 0
				print("[STATE] %s takes %d damage from %s (base: %d, power: %.2f, defense_mult: %.2f)" % [character_name, actual_damage, state_name, state.damage_per_turn, state.power_multiplier, defense_multiplier])
			else:
				# Healing state (negative damage)
				var healing = abs(actual_damage)
				current_health = min(current_health + healing, max_health)
				%BattlerHealthBar.value = current_health
				print("[STATE] %s recovers %d health from %s" % [character_name, healing, state_name])
		
		# Handle duration
		if state.turns_active > 0:
			state.turns_active -= 1
			if state.turns_active <= 0:
				states_to_remove.append(state_name)
	
	# Remove expired states
	for state_name in states_to_remove:
		remove_state(state_name)

func set_advancing(value: bool):
	is_advancing = value
	anim_tree.set("parameters/conditions/is_walking", value)

func set_defending(value: bool):
	is_defending = value

func _fade_and_remove() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Optional: Try to fade if the specific Alpha_Surface exists
	var surface = get_node_or_null("%Alpha_Surface")
	if surface and surface is GeometryInstance3D:
		var geo = surface as GeometryInstance3D
		geo.transparency = 0.0
		tween.tween_property(geo, "transparency", 1.0, 0.35)
	
	# Universal fallback: Scale the entire battler to 0
	tween.tween_property(self, "scale", Vector3.ZERO, 0.35)
	
	await tween.finished
	
	# Safety check: ensure the node hasn't already been destroyed by a scene change
	if is_instance_valid(self):
		queue_free()

## LEVEL-FOCUSED PROGRESSION
## Add experience and check for level up
func gain_experience(amount: int) -> void:
	if not exp_node:
		push_error("Battler %s has no Experience node" % character_name)
		return
	
	exp_node.add_exp(amount)
	print("%s gained %d EXP" % [character_name, amount])
	
	# Check if level up occurred
	while LevelProgression.check_level_up(self):
		pass

## Apply level-based stat scaling to this battler
## Called on _ready() and after level up
func apply_level_progression() -> void:
	if not stats:
		return
	
	# Calculate stats based on level and multipliers
	var base_stats = {
		"max_health": stats.max_health,
		"max_sp": stats.max_sp,
		"attack": stats.attack,
		"defense": stats.defense,
		"agility": stats.agility
	}
	
	var stat_multipliers = {
		"max_health": stats.health_multiplier,
		"max_sp": stats.sp_multiplier,
		"attack": stats.attack_multiplier,
		"defense": stats.defense_multiplier,
		"agility": stats.agility_multiplier
	}
	
	# Get calculated stats at current level
	var calculated = LevelProgression.get_stats_at_level(base_stats, stat_multipliers, stats.level)
	
	# Apply to battler
	max_health = calculated["max_health"]
	max_sp = calculated["max_sp"]
	attack = calculated["attack"]
	defense = calculated["defense"]
	agility = calculated["agility"]
	
	# Set current health/sp to max if first time initialization
	if current_health == 0:
		current_health = max_health
	if current_sp == 0:
		current_sp = max_sp
