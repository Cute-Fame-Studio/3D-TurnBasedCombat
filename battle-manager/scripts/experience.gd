class_name Experience 
extends Node

@export_group("Player")
@export var exp_to_level = 100;
@export var exp_to_level_multiplier = 5;
@export var exp_multi_reduction = 0.2;
@export var exp_reduce_start_level = 2;

var exp_total = 0;
var char_level = 1;

@export_group("Enemy")
@export var expOnKill = 0;

# 
#  Experience Handling
# 

func add_exp(amount: int):
	exp_total += amount
	check_level_up()

# 
#  Level Handling
# 

func check_level_up():
	if exp_total >= get_exp_next_level():
		do_level_up()
		return true
	else:
		return false

func do_level_up():
	char_level += 1
	exp_to_level *= exp_to_level_multiplier

	print("%s gains a level!" % [get_parent().character_name])
	print("%s is now level %d."% [get_parent().character_name, char_level])

	if char_level > exp_reduce_start_level:
		exp_to_level_multiplier -= exp_multi_reduction
	if exp_to_level_multiplier < 1:
		exp_to_level_multiplier = 1
		exp_multi_reduction = 0

# 
#  Get Methods
# 

func get_exp_to_level():
	return get_exp_next_level() - exp_total

func get_exp_next_level():
	return exp_to_level

func get_total_exp():
	return exp_total

func get_current_level():
	return char_level

func get_exp_on_kill():
	return expOnKill

# 
#  Set Methods
# 

func set_exp_total(amount: int):
	exp_total = amount
