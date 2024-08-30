extends VBoxContainer

# In your CharacterInfo.gd script
func add_character(character: Node):
	# Add a new label or update existing UI elements
	var label = Label.new()
	label.text = character.character_name
	add_child(label)

func update_player_info(character: Node):
	# Update player-specific UI elements
	$PlayerNameLabel.text = character.character_name
	$PlayerHealthLabel.text = str(character.current_health) + "/" + str(character.max_health)

func update_enemy_info(enemy: Node):
	# Update enemy-specific UI elements
	$EnemyNameLabel.text = enemy.character_name
	$EnemyHealthLabel.text = str(enemy.current_health) + "/" + str(enemy.max_health)
