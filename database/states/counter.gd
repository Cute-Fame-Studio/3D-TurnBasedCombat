class_name CounterState
extends State

@export var counter_damage_multiplier: float = 1.5
@export var counter_skill: Skill

func _init():
	state_name = "Counter"
	state_type = StateType.COUNTER
	damage_taken_multiplier = 0.0  # Not used for counter damage
	turns_active = -1  # Infinite until cured
	can_be_cured = true

# Called when this battler is attacked while having Counter state
func perform_counter(defender: Battler, attacker: Battler) -> void:
	# Only trigger if counter is still active
	if not defender.active_states.has(state_name):
		return
	
	print("[COUNTER] %s counters %s's attack!" % [defender.character_name, attacker.character_name])
	
	# Delay slightly for visual feedback
	await defender.get_tree().create_timer(0.2).timeout
	
	if counter_skill:
		# Use the defined counter skill
		print("[COUNTER] Using skill: ", counter_skill.skill_name)
		defender.use_skill(counter_skill, attacker)
	else:
		# Default counter attack
		print("[COUNTER] Using default counter attack")
		defender._try_animation("attack")
		await defender.get_tree().create_timer(0.5).timeout
		
		var counter_damage = Formulas.physical_damage(
			defender, 
			attacker, 
			int(defender.attack * counter_damage_multiplier)
		)
		attacker.take_damage(counter_damage, defender)
