## BattlerCombatHelper
## Extracted combat utility functions for battlers.
## Usage: Call these from battler.gd to reduce complexity and improve readability.
## This keeps logic organized while remaining tightly coupled to per-battler state.

class_name BattlerCombatHelper
extends Node

# ============================================================================
# MOVEMENT HELPER FUNCTIONS
# ============================================================================

## Calculate target position for advancement toward a target battler.
## Returns the position where this battler should stop (respecting movement_distance).
static func calculate_advance_position(attacker: Battler, target: Battler, movement_distance: float) -> Vector3:
	var direction = (target.global_position - attacker.global_position).normalized()
	return target.global_position - direction * movement_distance

## Start a movement tween from one position to another.
## Returns the tween for optional cancellation/chaining.
static func start_movement_tween(battler: Battler, from_pos: Vector3, to_pos: Vector3, 
		speed: float, speed_multiplier: float) -> Tween:
	var distance = from_pos.distance_to(to_pos)
	var duration = distance / (speed * speed_multiplier)
	
	var tween = battler.create_tween()
	tween.set_speed_scale(speed_multiplier)
	tween.tween_property(battler, "global_position", to_pos, duration)
	
	return tween

## Check if a battler is currently stuck in advancing state.
## Returns true if is_advancing is true but hasn't moved within timeout period.
static func is_movement_stuck(battler: Battler, start_position: Vector3, _timeout_threshold: float = 0.1) -> bool:
	if not battler.is_advancing:
		return false
	
	# Small movement threshold to account for floating point precision
	var distance_moved = start_position.distance_to(battler.global_position)
	return distance_moved < 0.01

# ============================================================================
# TARGETING HELPER FUNCTIONS
# ============================================================================

## Validate if a target is acceptable for an action.
## Prevents self-targeting and validates team alignment.
static func is_valid_action_target(attacker: Battler, target: Battler, is_damage_action: bool) -> bool:
	if not target or attacker == target:
		return false
	
	if target.is_defeated():
		return false
	
	# For damage actions, don't allow hitting allies
	if is_damage_action and attacker.team == target.team:
		return false
	
	return true

## Get the battle manager from the scene tree.
static func get_battle_manager() -> Node:
	var root = Engine.get_main_loop().root
	if root:
		return root.get_tree().get_first_node_in_group("battle_manager")
	return null

# ============================================================================
# ANIMATION & EFFECT HELPER FUNCTIONS
# ============================================================================

## Safely attempt to play an animation on the state machine.
## Includes error checking and fallback behavior.
static func try_play_animation(battler: Battler, anim_name: String) -> bool:
	if not anim_name or anim_name.is_empty():
		print("[AnimError] Empty animation name provided")
		return false
	
	if not battler.state_machine:
		print("[AnimError] state_machine not initialized on ", battler.character_name)
		return false
	
	battler.state_machine.travel(anim_name)
	print("[Anim] Playing: ", anim_name, " on ", battler.character_name)
	
	return true

## Apply fallback damage if animation callback didn't fire.
## Only applies if the action hasn't been processed yet.
static func apply_fallback_damage(attacker: Battler, target: Battler, skill: Skill = null) -> void:
	var battle_manager = get_battle_manager()
	if not battle_manager:
		return
	
	# Check if damage already processed
	if battle_manager.damage_processed_this_turn:
		return
	
	# Check if this battler allows fallback
	if not attacker.allow_animation_fallback:
		print("[Fallback] Damage fallback disabled for ", attacker.character_name)
		return
	
	print("[Fallback] Animation didn't trigger damage, applying fallback for ", attacker.character_name)
	
	var damage = 0
	if skill:
		damage = Formulas.calculate_damage(attacker, target, skill)
	else:
		damage = attacker.get_attack_damage(target)
	
	if damage > 0:
		battle_manager.damage_calculation(attacker, target, damage)

# ============================================================================
# STATE MANAGEMENT HELPER FUNCTIONS
# ============================================================================

## Initialize the states dictionary and subscribe to state changes.
static func initialize_states(battler: Battler) -> void:
	battler.active_states = {}
	print("[State] Initialized state system for ", battler.character_name)

## Process all active states for a battler.
## Handles DOT/HOT, duration tracking, and cleanup.
static func tick_states(battler: Battler) -> void:
	var states_to_remove = []
	
	for state_name in battler.active_states:
		var state = battler.active_states[state_name]
		
		# Handle DOT/HOT effects with defense multiplier
		if state.damage_per_turn != 0:
			var defense_multiplier = max(0.1, 1.0 - (float(battler.defense) / 100.0))
			var actual_damage = int(state.damage_per_turn * state.power_multiplier * defense_multiplier)
			actual_damage = max(1, actual_damage)
			
			if actual_damage > 0:
				var damage_num: DamageNumber = battler.floating_damage_num.instantiate()
				damage_num.value = actual_damage
				battler.damage_indicator_subviewport.add_child(damage_num)
				battler.current_health -= actual_damage
				battler.get_node("%BattlerHealthBar").value = battler.current_health
				if battler.current_health < 0:
					battler.current_health = 0
				print("[State] %s takes %d damage from %s" % [battler.character_name, actual_damage, state_name])
			else:
				var healing = abs(actual_damage)
				battler.current_health = min(battler.current_health + healing, battler.max_health)
				battler.get_node("%BattlerHealthBar").value = battler.current_health
				print("[State] %s recovers %d health from %s" % [battler.character_name, healing, state_name])
		
		# Handle duration
		if state.turns_active > 0:
			state.turns_active -= 1
			if state.turns_active <= 0:
				states_to_remove.append(state_name)
	
	# Remove expired states
	for state_name in states_to_remove:
		remove_state(battler, state_name)

## Remove a state from a battler.
static func remove_state(battler: Battler, state_name: String) -> void:
	if battler.active_states.has(state_name):
		battler.active_states.erase(state_name)
		print("[State] %s is no longer affected by %s" % [battler.character_name, state_name])

## Apply a state to a battler.
static func apply_state(battler: Battler, state: State) -> void:
	if state == null:
		return
	battler.active_states[state.state_name] = state.duplicate()
	print("[State] %s was afflicted with %s!" % [battler.character_name, state.state_name])
