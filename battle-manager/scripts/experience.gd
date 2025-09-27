class_name Experience 
extends Node

@export_group("Player")
# Total amount of experience required to hit the next level - updated each time do_level_up() function runs
@export var exp_to_level = 100;
# Multiplier for updating exp_to_level - updated during do_level_up() function to slowly scale down until equals 1
@export var exp_to_level_multiplier = 5;
# Value which scales down the exp_to_level_multiplier
@export var exp_multi_reduction = 0.2;
# Character level that exp_multi_reduction starts scaling down exp_to_level_multiplier
@export var exp_reduce_start_level = 2;

# Total accumulted exp - use add_exp(amount: int) function to increase
var exp_total = 0;
# Current character level - use do_level_up() function to increase
var char_level = 1;

@export_group("Enemy")
# Amount of exp enemy grants when killed
@export var expOnKill = 0;

# 
#  Experience Handling
#
#  Active Call - Used in other scripts to interact with experience
#  Passive Call - Only used internally within experience script
#  Get Methods - Used to output numeric values without changing them
#  Set Methods - Used to alter internal experience values, if needed
# 

# Active Call
# Use anytime exp is increased
func add_exp(amount: int):
	exp_total += amount
	check_level_up()

# 
#  Level Handling
# 

# Passive Call
# Runs anytime add_exp(amount: int) is called
func check_level_up():
	if exp_total >= get_exp_next_level():
		do_level_up()
		return true
	else:
		return false

# Passive Call
# Activates when check_level_up() determines a level increase
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

# Outputs value still needed to hit the next char_level
func get_exp_to_level():
	return get_exp_next_level() - exp_total

# Outputs total value needed to hit the next char_level
func get_exp_next_level():
	return exp_to_level

# Outputs current exp_total
func get_total_exp():
	return exp_total

# Outputs current char_level
func get_current_level():
	return char_level

# Outputs experience enemy gives when killed - expOnKill
func get_exp_on_kill():
	return expOnKill

# 
#  Set Methods
# 

# Used to set exp_total to a precise value - not generally used
func set_exp_total(amount: int):
	exp_total = amount
