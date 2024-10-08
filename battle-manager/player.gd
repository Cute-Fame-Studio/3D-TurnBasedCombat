extends CharacterBody3D

@export var PlayerData: Resource 

var character_name: String
var max_health: int
var attack: int
var defense: int
var speed: int

var current_health: int
var is_defending: bool = false

func _ready():
	if PlayerData:
		character_name = PlayerData.character_name
		max_health = PlayerData.max_health
		attack = PlayerData.attack
		defense = PlayerData.defense
		speed = PlayerData.speed
		
		current_health = max_health
		add_to_group("players")
	else:
		push_error("PlayerData resource not set!")

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
