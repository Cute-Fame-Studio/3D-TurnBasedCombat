class_name Ally
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
@onready var exp_node: Experience = get_node("Experience")

func _ready():
	if PlayerData:
		character_name = PlayerData.character_name
		max_health = PlayerData.max_health
		attack = PlayerData.attack
		defense = PlayerData.defense
		speed = PlayerData.speed
		
		current_health = max_health
		for skill:CharacterAbilities in skill_list:
			match skill.damage_type:
				"Physical":
					skill.use_skill.connect(skill_attack)
				"Healing":
					skill.use_skill.connect(skill_heal)
		add_to_group("players")
	else:
		push_error("PlayerData resource not set!")
	print("Current Element: ",PlayerData.element)

func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage(target) -> int:
	var damage = attack + randi() % 5
	return Formulas.physical_damage(self, target, damage)

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

func attack_anim(target) -> int:
	state_machine.travel("attack")
	return get_attack_damage(target) # Needing to transfer to dealing damage through animation. Not after! 
	# Some animations may do damage multiple times during their attack, It is better to dynamically show the damage being dealt.

#func deal_damage():
	#return get_attack_damage(target)

func use_skill(skill:CharacterAbilities, target) -> int:
	match skill.damage_type:
		"Physical":
			return skill_attack(target, skill)
		"Healing":
			return skill_heal(skill)
		_:
			return skill_attack(target, skill)

func skill_attack(target, skill:CharacterAbilities):
	state_machine.travel(skill.anim_tree_name)
	return Formulas.calculate_damage(self, target, skill)

func skill_heal(skill:CharacterAbilities):
	state_machine.travel(skill.anim_tree_name)
	return skill.number_value

func wait_attack():
	if self.is_defending:
		return
	await $AnimationTree.animation_finished
	battle_idle()

func get_exp_stat():
	return exp_node

# Save System
func on_save_game(save_data):
	var new_data = BattlerData.new()
	new_data.current_hp = current_health
	new_data.current_exp = get_exp_stat().get_total_exp()
	new_data.current_level = get_exp_stat().get_current_level()
	new_data.skill_list = skill_list
	
	save_data["charNameOrID"] = new_data # replace string with key when created

func on_load_game(load_data):
	var save_data = load_data["charNameOrID"] as BattlerData # replace string with key when created
	if save_data == null: print("Battler data is empty."); return # exit function if no data
	
	current_health = save_data.current_hp
	get_exp_stat().exp_total = save_data.current_exp
	get_exp_stat().char_level = save_data.current_level
	skill_node.character_skills = save_data.skill_list
