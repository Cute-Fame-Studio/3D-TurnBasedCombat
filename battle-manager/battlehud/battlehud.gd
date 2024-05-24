extends Control

var activePlayer
var character = CharacterBody3D
var enemy
var characters = []

signal start_combat(enemyProperty)
signal add_character(character)

@export var combat = true

func _process(_delta):
	if combat:
		for character in characters:
			var moves = character["moves"].keys()
			var i = 0
			var labels = self.get_child(0).get_children()
			for move in moves:
				labels[i].text = move
				i += 1

func _do_move(move):
	print(move["damage"])
	var damagePoints = move["damage"]
	enemy.damage.emit(damagePoints)

func _on_add_character(character):
	characters.append(character)
	Activeplayer._set_active_character(character)

func _on_start_combat(enemyProperty):
	combat = true
	enemy = enemyProperty


func _on_attack_pressed():
	var characterKey = Activeplayer.activeCharacter.keys()
	print(characterKey)
	var moves = Activeplayer.activeCharacter["moves"]
	print(moves)
	var moveKeys = moves.keys()
	if moves.size() > 0:
		_do_move(moves["Attack"])


func _on_skills_pressed():
	print("This cannot be used.")


func _on_defend_pressed():
	print("This cannot be used.")


func _on_item_pressed():
	print("This cannot be used.")


func _on_run_pressed():
	print("This cannot be used.")
