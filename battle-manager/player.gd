extends CharacterBody3D

@export var PlayerData: Resource 

var character_name: String
var max_health: int
var attack: int
var defense: int
var speed: int

var current_health: int
var is_defending: bool = false

@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var skill_node: Node = get_node("SkillList")
@onready var skill_list: Array[Resource] = skill_node.get_skills()
@onready var exp_node: Node = get_node("Experience")

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

func take_healing(amount: int):
	var healing = min(amount, max_health - current_health)

	current_health += healing
	print("%s received %d healing. Health: %d/%d" % [character_name, healing, current_health, max_health])
	return healing

func defend():
	is_defending = true
	print("%s is defending. Defense doubled for the next attack." % character_name)

func gain_experience(amount: int):
	print("%s gained %d experience!" % [character_name, amount])
	print ("%s needs %d to level up!" % [character_name, get_exp_stat().get_exp_to_level()])

func battle_run():
	pass

func battle_item():
	pass 
	# Intergrate gloot. Trying to do this alone may cause mistakes.

func battle_idle():
	state_machine.travel("battle_idle")

func attack_anim():
	state_machine.travel("attack")
	return get_attack_damage()

func skill_attack():
	state_machine.travel(skill_list[0].anim_tree_name)
	return skill_list[0].number_value

func skill_heal():
	state_machine.travel(skill_list[1].anim_tree_name)
	return skill_list[1].number_value

func wait_attack():
	if self.is_defending:
		return
	await $AnimationTree.animation_finished
	battle_idle()

func get_exp_stat():
	return exp_node
