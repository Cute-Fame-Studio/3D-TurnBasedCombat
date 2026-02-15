class_name State
extends Resource

enum StateType {
	DOT,           # Damage over time (poison, burn)
	COUNTER,       # Counter attacks
	BUFF,         # Stat increases
	DEBUFF        # Stat decreases
}

@export var state_name: String = ""
@export var state_description: String = ""
@export var state_type: StateType
@export_range(0, 100, 1) var damage_per_turn: int = 0  ## Base damage/healing per turn.
@export_range(0.0, 2.0, 0.1) var power_multiplier: float = 1.0  ## Multiplier for state damage. Scales with attacker's attack stat.
@export_range(-1, 99, 1) var turns_active: int = -1  ## Duration in turns. -1 means infinite until cured.
@export var can_be_cured: bool = true  ## Whether this state can be removed by cure skills.
@export_range(0.1, 2.0, 0.1) var damage_taken_multiplier: float = 1.0  ## Incoming damage multiplier. 1.0 = normal, 1.5 = 50% more damage, 0.5 = 50% less damage
