class_name CounterState
extends State

@export var counter_damage_multiplier: float = 1.5
@export var counter_skill: Skill

func _init():
	state_type = StateType.COUNTER
	damage_reduction = 0.5

func perform_counter(battler: Battler, attacker: Battler) -> void:
	print("[COUNTER] %s counters %s's attack!" % [battler.character_name, attacker.character_name])
	
	# Wait for attacker's animation to finish
	await battler.get_tree().create_timer(0.3).timeout
	
	if counter_skill:
		battler.use_skill(counter_skill, attacker)
	else:
		battler.state_machine.travel("attack")
		var counter_damage = Formulas.physical_damage(
			battler, 
			attacker, 
			battler.attack * counter_damage_multiplier
		)
		attacker.take_damage(counter_damage, battler)  # Now properly passes both parameters
