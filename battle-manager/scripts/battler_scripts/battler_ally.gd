class_name Ally
extends CharacterBody3D

signal anim_damage()

@export var stats: BattlerStats 
@export var default_attack: Skill # Basic attack as a skill

var character_name: String
var max_health: int
var attack: int
var defense: int
var speed: int

var current_health: int
var current_sp: int = 100  # Add SP variables
var max_sp: int = 100      # Add max SP
var is_defending: bool = false
var current_target = null

@onready var basic_attack_animation = "attack"
@onready var state_machine = $AnimationTree["parameters/playback"]
@onready var skill_node: Node = get_node("SkillList")
@onready var skill_list: Array[Skill] = []
@onready var exp_node: Experience = get_node("Experience")

func _ready():
	if stats:
		# Basic stats
		character_name = stats.character_name
		max_health = stats.max_health
		attack = stats.attack
		defense = stats.defense
		speed = stats.speed
		
		# SP stats
		max_sp = stats.max_sp
		current_sp = max_sp
		current_health = max_health
		
		add_to_group("players")
		
		if skill_node and skill_node.has_method("get_skills"):
			for skill in skill_node.get_skills():
				if skill is Skill:
					skill_list.append(skill)
		
		if default_attack:
			skill_list.append(default_attack)
	else:
		push_error("BattlerStats resource not set!")
	print("Current Element: ", stats.element)

func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage(target) -> int:
	print("PLAYER: calculating damage for target: ", target.name)
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
	print("%s needs %d to level up!" % [character_name, get_exp_stat().get_exp_to_level()])

func battle_run():
	pass

func battle_item():
	pass 
	# Intergrate a simple inventory system. Trying to do this alone may cause mistakes.

func battle_idle():
	state_machine.travel("battle_idle")

func attack_anim(target) -> int:
	print("PLAYER: Starting attack for target: ", target.name)
	current_target = target
	state_machine.travel("attack")
	return 0 # Don't return damage here, handled by animation
	#return get_attack_damage(target) # Needing to transfer to dealing damage through animation. Not after! 
	# Some animations may do damage multiple times during their attack, It is better to dynamically show the damage being dealt.

#func deal_damage():
	#return get_attack_damage(target)

func use_skill(skill:Skill, target) -> int:
	if skill.can_use(self):
		state_machine.travel(skill.animation_name)
		skill.apply_costs(self)
		
		match skill.effect_type:
			"Damage":
				return Formulas.calculate_damage(self, target, skill)
			"Heal":
				return skill.base_power
			_:
				return 0
	return 0

func wait_attack():
	if self.is_defending:
		return
	await $AnimationTree.animation_finished
	battle_idle()

func get_exp_stat():
	return exp_node

# # #
# Call methods
# # #
func call_attack():
	print("PLAYER: Animation hit point reached")
	anim_damage.emit()

# # #
# Save System
# # #
func on_save_game(save_data):
	var new_data = BattlerData.new()
	new_data.current_health = current_health  # Using consistent property name
	new_data.current_sp = current_sp
	new_data.current_exp = get_exp_stat().get_total_exp()
	new_data.current_level = get_exp_stat().get_current_level()
	new_data.skill_list = skill_list
	
	save_data["charNameOrID"] = new_data

func on_load_game(load_data):
	var save_data = load_data["charNameOrID"] as BattlerData
	if save_data == null: 
		print("Battler data is empty.")
		return
	
	current_health = save_data.current_health  # Using consistent property name
	current_sp = save_data.current_sp
	get_exp_stat().exp_total = save_data.current_exp
	get_exp_stat().char_level = save_data.current_level
	skill_node.character_skills = save_data.skill_list

func regenerate_sp():
	if stats and current_sp < max_sp:
		var regen_amount = stats.sp_regen
		current_sp = min(current_sp + regen_amount, max_sp)
		print("%s recovered %d SP. SP: %d/%d" % [character_name, regen_amount, current_sp, max_sp])
