## CounterState
## Handles counter attacks for battlers with the Counter state.
## This state triggers automatically when the afflicted battler takes damage from a non-ally.
## 
## Usage:
## - Apply this state to a battler to enable counter attacks
## - Configure counter_skill to define what attack is used for counters
## - Set interrupt_attacker to true for dramatic immediate counters (Like a Dragon style)
## - Set interrupt_attacker to false to let attacker return first before counter (safer, less code)

class_name CounterState
extends State

@export var counter_damage_multiplier: float = 1.5
@export var counter_skill: Skill
@export var interrupt_attacker: bool = true  ## If true, counter fires while attacker is close. If false, wait for return.
@export var max_counters_per_turn: int = 2  ## Limit how many times counter can trigger per turn

var counters_used_this_turn: int = 0  ## Track usage this turn

func _init():
	state_name = "Counter"
	state_type = StateType.COUNTER
	damage_taken_multiplier = 0.0  # Not used for counter damage
	turns_active = -1  # Infinite until cured
	can_be_cured = true
	counters_used_this_turn = 0

## Reset counter usage at start of battler's turn (call from BattleManager)
func reset_turn_usage() -> void:
	counters_used_this_turn = 0

## Called when this battler is attacked while having Counter state
## Only triggers against non-allies (damage skills hitting enemies)
func perform_counter(defender: Battler, attacker: Battler) -> void:
	# Only trigger if counter is still active
	if not defender.active_states.has(state_name):
		return
	
	# Safety: Don't counter allies
	if attacker.team == defender.team:
		print("[COUNTER] Prevented counter against teammate: ", attacker.character_name)
		return
	
	# Check usage limit
	if counters_used_this_turn >= max_counters_per_turn:
		print("[COUNTER] Counter already used ", counters_used_this_turn, "/", max_counters_per_turn, " times this turn. Skipping.")
		return
	
	counters_used_this_turn += 1
	print("[COUNTER] %s counters %s's attack! (%d/%d)" % [defender.character_name, attacker.character_name, counters_used_this_turn, max_counters_per_turn])
	
	# Delay slightly for visual feedback
	await defender.get_tree().create_timer(0.2).timeout
	
	if interrupt_attacker:
		# INTERRUPT mode: Counter happens immediately while attacker is in position
		print("[COUNTER] INTERRUPT mode - countering in place")
		await _execute_counter_attack(defender, attacker)
	else:
		# DELAYED mode: Let attacker return first, then counter
		print("[COUNTER] DELAYED mode - waiting for attacker to return")
		await _wait_for_attacker_return(attacker)
		await _execute_counter_attack(defender, attacker)

## Execute the actual counter attack
func _execute_counter_attack(defender: Battler, attacker: Battler) -> void:
	# Get battle manager to set up state for damage callback
	var battle_manager = defender.get_tree().get_first_node_in_group("battle_manager")
	
	if counter_skill:
		print("[COUNTER] Using skill: ", counter_skill.skill_name)
		
		# SET ATTACKER AS STUNNED - will pause before they return to position
		attacker.is_counter_stunned = true
		
		# Set up battle manager state so damage callback knows this is a counter
		if battle_manager:
			battle_manager.current_character = defender
			battle_manager.current_target = attacker
			battle_manager.queued_action = "counter"  # Mark as counter action
			battle_manager.queued_skill = counter_skill
			battle_manager.current_skill_effect_type = counter_skill.effect_type
			# Reset damage flag so this action can process damage
			battle_manager.damage_processed_this_turn = false
		
		# AWAIT the counter skill to complete before returning
		await defender.use_skill(counter_skill, attacker)
		
		# Clear the queued action after counter completes
		if battle_manager:
			battle_manager.queued_action = ""
	else:
		# Default counter attack (basic attack with multiplier)
		print("[COUNTER] Using default counter attack")
		attacker.is_counter_stunned = true  # Stun attacker
		
		defender._try_animation("attack")
		await defender.get_tree().create_timer(0.5).timeout
		
		var counter_damage = Formulas.physical_damage(
			defender, 
			attacker, 
			int(defender.attack * counter_damage_multiplier)
		)
		attacker.take_damage(counter_damage, defender)

## Wait for attacker to return to original position before counter
func _wait_for_attacker_return(attacker: Battler) -> void:
	var timeout = 5.0
	var elapsed = 0.0
	
	while attacker.is_advancing and elapsed < timeout:
		await attacker.get_tree().create_timer(0.1).timeout
		elapsed += 0.1
	
	print("[COUNTER] Attacker returned (or timeout), proceeding with counter")
