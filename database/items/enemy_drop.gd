class_name EnemyDrop
extends Resource

@export var item: Item
@export_range(0.0, 100.0, 0.1) var drop_chance: float = 25.0
@export_range(1, 99, 1) var min_amount: int = 1
@export_range(1, 99, 1) var max_amount: int = 1

func roll_amount() -> int:
	return randi_range(min_amount, max_amount)
