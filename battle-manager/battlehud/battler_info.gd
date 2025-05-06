extends VBoxContainer

# Declare the progress bar node
@onready var name_label = $PlayerNameLabel 
@onready var health_bar = $PlayerHealthBar
@onready var sp_bar = $PlayerSPBar

func add_character(character: Node):
	if character:
		show()
		update_character_info(character)
		

func update_character_info(character: Node):
	if character and is_instance_valid(character):
		name_label.text = character.character_name
		health_bar.max_value = character.max_health
		health_bar.value = character.current_health

func update_player_stats(character: Node):
	if character and is_instance_valid(character):
		$PlayerNameLabel.text = character.character_name
		$PlayerHealthBar.max_value = character.max_health
		$PlayerHealthBar.value = character.current_health
		sp_bar.max_value = character.max_sp 
		sp_bar.value = character.current_sp

func update_enemy_stats(character: Node):
	if character and is_instance_valid(character):
		name_label.text = character.character_name
		health_bar.max_value = character.max_health
		health_bar.value = character.current_health
