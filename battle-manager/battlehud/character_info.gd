extends VBoxContainer

# Declare the progress bar node
@onready var player_health_bar: ProgressBar = $PlayerHealthBar

func add_character(character: Node):
	# Add a new label or update existing UI elements
	var label = Label.new()
	label.text = character.character_name
	add_child(label)

func update_player_info(character: Node):
	# Update player-specific UI elements
	$PlayerNameLabel.text = character.character_name
	$PlayerHealthBar.max_value = character.max_health
	$PlayerHealthBar.value = character.current_health
