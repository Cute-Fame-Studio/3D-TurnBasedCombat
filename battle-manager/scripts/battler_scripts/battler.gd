class_name Battler
extends CharacterBody3D

signal anim_damage()
enum TEAM {ALLY, ENEMY}

@export var stats: BattlerStats
@export var default_attack:Skill # Basic attack as a skill
@export_group("Team and AI Controls")
## Define the battler's Team - Allies are Player-controlled
@export var team: TEAM # This will default to ALLY
## If the battler will act independent of player selection, how optimal is it?
## 0 = Randumb, 100 = Big Brain
@export_range(0, 100, 1) var intelligence:int
enum AIType {AGGRESSIVE, DEFENSIVE}
## If this battler acts on its own, what is its strategy/approach to combat?
## Interacts with intelligence to make "optimal" decision.
@export var ai_type:AIType

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

# Targeting controls
@onready var material:Material = %Alpha_Surface.material_override
@onready var select_outline:Shader = preload("res://assets/shaders/battler_select_shader.gdshader")
var is_selectable:bool = false :
	set(selectable):
		is_selectable = selectable
		if !is_selectable:
			is_targeted = false
var is_targeted:bool = false :
	set(targeted):
		is_targeted = targeted
		if targeted:
			var shader_mat:ShaderMaterial = ShaderMaterial.new()
			shader_mat.shader = select_outline
			shader_mat.set_shader_parameter("color", Color(Color.WHITE))
			shader_mat.set_shader_parameter("thickness", 0.02)
			shader_mat.set_shader_parameter("alpha", 1.0)
			material.next_pass = shader_mat
		else:
			material.next_pass = null
var mouse_hover:bool = false :
	set(hovering):
		mouse_hover = hovering
		if hovering and is_selectable and !is_targeted:
			var shader_mat:ShaderMaterial = ShaderMaterial.new()
			shader_mat.shader = select_outline
			shader_mat.set_shader_parameter("color", Color(Color.WHITE))
			shader_mat.set_shader_parameter("thickness", 0.02)
			shader_mat.set_shader_parameter("alpha", 0.2)
			material.next_pass = shader_mat
		elif !hovering and !is_targeted:
			material.next_pass = null
		elif !is_selectable:
			material.next_pass = null

@export_group("Special Dependencies")
@onready var basic_attack_animation = "attack"
@onready var state_machine = $AnimationTree["parameters/playback"]
@export var skill_node: SkillList
@onready var skill_list: Array[Skill] = []
@onready var exp_node: Experience = get_node("Experience")
@export var damage_indicator_subviewport:SubViewport

func _ready():	
	SignalBus.select_target.connect(check_select_target)
	SignalBus.allow_select_target.connect(set_selectable)
	if !default_attack:
		default_attack = load("res://database/skills/normal_attack.tres")
	
	# If all battlers use the same material, or if there are duplicate battlers of the same type
	# this ensures that they have uniquely assigned materials so the shader does not apply
	# to ALL of them
	var dupe_mat:Material = material.duplicate()
	%Alpha_Surface.material_override = dupe_mat
	material = %Alpha_Surface.material_override
	
	if stats:
		# Basic stats
		character_name = stats.character_name
		%BattlerNameLabel.text = character_name
		
		max_health = stats.max_health
		current_health = max_health
		%BattlerHealthBar.max_value = max_health
		%BattlerHealthBar.value = current_health
		
		attack = stats.attack
		defense = stats.defense
		speed = stats.speed
		
		# SP stats
		max_sp = stats.max_sp
		current_sp = max_sp
		
		if skill_node:
			var updated_skill_list:Array[Skill] = skill_node.get_skills()
			for skill in updated_skill_list:
				if skill is Skill and !skill_list.has(skill):
					skill_list.append(skill)
		
		if default_attack:
			skill_list.append(default_attack)
	else:
		push_error("BattlerStats resource not set!")
	
	# Assign to group based on team
	if team == TEAM.ENEMY:
		add_to_group("enemies")
	elif team == TEAM.ALLY:
		add_to_group("players")
	print("Current Element: ", stats.element)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Select") and is_selectable and mouse_hover:
		select_target()

func _mouse_enter() -> void: has_hover(true)
func _mouse_exit() -> void: has_hover(false)
func has_hover(hover:bool = false) -> void:
	mouse_hover = hover

func set_selectable(can_target:bool) -> void:
	is_selectable = can_target

func check_select_target(target:Battler) -> void:
	if target != self and is_targeted:
		deselect_as_target()

func select_target() -> void:
	# Will probably want to also add logic that prevents selecting invalid targets
	is_targeted = true
	SignalBus.select_target.emit(self)

func deselect_as_target() -> void:
	is_targeted = false


func is_defeated() -> bool:
	return current_health <= 0

func get_attack_damage(target) -> int:
	print("PLAYER: calculating damage for target: ", target.name)
	var damage = attack + randi() % 5
	return Formulas.physical_damage(self, target, damage)

@onready var floating_damage_num:PackedScene = preload("res://battle-manager/damage_number.tscn")
func take_damage(amount: int):
	var damage_reduction = defense
	if is_defending:
		damage_reduction *= 2
		is_defending = false
	
	var damage_num:DamageNumber = floating_damage_num.instantiate()
	var damage_taken = max(0, amount - damage_reduction)
	damage_num.value = damage_taken
	damage_indicator_subviewport.add_child(damage_num)
	current_health -= damage_taken
	%BattlerHealthBar.value = current_health
	if current_health < 0:
		current_health = 0
	print("%s took %d damage. Health: %d/%d" % [character_name, damage_taken, current_health, max_health])

func take_healing(amount: int):
	var healing = min(amount, max_health - current_health)

	current_health += healing
	%BattlerHealthBar.value = current_health
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
