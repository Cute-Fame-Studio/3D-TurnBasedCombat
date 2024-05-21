extends Node3D

@onready var enemy = get_tree().get_first_node_in_group("Enemy")
@onready var BattleHud = get_tree().get_first_node_in_group("BattleHud")

@export var moves = {
	"Attack": {
		"damage": 15,
		"manaCost": 0
	},
	"Block": {
		"damage": 0,
		"manaCost": 0
	}
}

@export var character = {
	"name": "Eben",
	"totalMana:": 100,
	"totalHP": 100,
	"moves": moves
}

func _ready():
	BattleHud.add_character.emit(character)
	BattleHud.start_combat.emit(enemy)


func _on_move_1_pressed():
	var moveKeys = moves.keys()
	if moves.size() > 0:
		_do_move(moves[moveKeys[0]])

func _on_move_2_pressed():
	var moveKeys = moves.keys()
	if moves.size() > 1:
		_do_move(moves[moveKeys[1]])


func _on_move_3_pressed():
	var moveKeys = moves.keys()
	if moves.size() > 2:
		_do_move(moves[moveKeys[2]])


func _on_move_4_pressed():
	var moveKeys = moves.keys()
	if moves.size() > 3:
		_do_move(moves[moveKeys[3]])

func _do_move(move):
	print(move["damage"])
	var damagePoints = move["damage"]
	enemy.damage.emit(damagePoints)

