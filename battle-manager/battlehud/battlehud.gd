extends CanvasLayer

signal action_selected(action: String, target: CharacterBody3D)

var active_character: CharacterBody3D
var enemy: CharacterBody3D
var characters: Array[CharacterBody3D] = []

@export var combat: bool = false

@onready var action_buttons = $HBoxContainer
@onready var attack_button = $HBoxContainer/Attack
@onready var defend_button = $HBoxContainer/Defend
@onready var character_info = $CharacterInfo

func _ready():
	_connect_signals()
	hide_action_buttons()
	
	# Ensure all required nodes exist
	if not character_info:
		push_error("CharacterInfo node not found in BattleHUD. Please add a Label node named CharacterInfo.")
		return

func _connect_signals():
	if attack_button:
		attack_button.pressed.connect(_on_attack_pressed)
	else:
		push_error("Attack button not found in BattleHUD.")
	
	if defend_button:
		defend_button.pressed.connect(_on_defend_pressed)
	else:
		push_error("Defend button not found in BattleHUD.")

func _on_attack_pressed():
	action_selected.emit("attack", enemy)

func _on_defend_pressed():
	action_selected.emit("defend", null)

func show_action_buttons(character: CharacterBody3D):
	active_character = character
	if action_buttons:
		action_buttons.show()
	else:
		push_error("Action buttons container not found in BattleHUD.")

func hide_action_buttons():
	if action_buttons:
		action_buttons.hide()
	else:
		push_error("Action buttons container not found in BattleHUD.")

func update_character_info():
	if not character_info:
		push_error("CharacterInfo node not found in BattleHUD.")
		return
	
	if active_character:
		character_info.text = "%s\nHP: %d/%d" % [active_character.character_name, active_character.current_health, active_character.max_health]
	else:
		character_info.text = "No active character"

func on_start_combat(enemy_node: CharacterBody3D):
	combat = true
	enemy = enemy_node
	update_character_info()

func on_add_character(character: CharacterBody3D):
	characters.append(character)
	if not active_character:
		active_character = character
	update_character_info()

func show_battle_result(result: String):
	var result_label = Label.new()
	result_label.text = result
	result_label.anchor_left = 0.5
	result_label.anchor_top = 0.5
	result_label.anchor_right = 0.5
	result_label.anchor_bottom = 0.5
	result_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	result_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(result_label)

func set_active_character(character: CharacterBody3D):
	active_character = character
	update_character_info()
