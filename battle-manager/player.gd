extends CharacterBody3D

@export var character_name: String = ""
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 5

var current_health: int
var is_defending: bool = false

func _ready():
	current_health = max_health
	add_to_group("players")

func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage() -> int:
	return attack + randi() % 5

func take_damage(amount: int):
	var damage_reduction = defense
	if is_defending:
		damage_reduction *= 2
		is_defending = false

	var damage_taken = max(0, amount - damage_reduction)
	current_health -= damage_taken
	if current_health < 0:
		current_health = 0
	print("%s took %d damage. Health: %d/%d" % [character_name, damage_taken, current_health, max_health])

func defend():
	is_defending = true
	print("%s is defending. Defense doubled for the next attack." % character_name)

func gain_experience(amount: int):
	print("%s gained %d experience!" % [character_name, amount])
