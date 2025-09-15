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
@export var damage_per_turn: int = 0
@export var turns_active: int = -1  # -1 means infinite until cured
@export var can_be_cured: bool = true
@export var damage_reduction: float = 1.0  # 1.0 = normal damage, 0.5 = half damage, etc.
