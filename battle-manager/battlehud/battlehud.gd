extends CanvasLayer

signal action_selected(action: String, target)

@onready var action_buttons: VBoxContainer = $Control/ActionButtons
@onready var character_info: VBoxContainer = $Control/PlayerStats
@onready var enemy_stats: VBoxContainer = $Control/EnemyStats
@onready var battle_result_label: Label = $Control/BattleResultLabel

var active_character: Node = null
var enemy: Node = null

# Health bar-related nodes
@onready var player_health_bar: ProgressBar = $Control/PlayerStats/PlayerHealthBar
@onready var enemy_health_bar: ProgressBar = $Control/EnemyStats/EnemyHealthBar

func _ready():
	battle_result_label.hide()
	hide_action_buttons()

	# Initialize health bars
	player_health_bar.hide()

func on_start_combat(enemy_node: Node):
	enemy = enemy_node
	update_enemy_health_bar()

func on_add_character(character: Node):
# Update the CharacterInfo VBoxContainer with the new character info
# You might need to implement a method in CharacterInfo to handle this
	if character_info.has_method("add_character"):
		character_info.add_character(character)
	else:
		print("Warning: CharacterInfo node doesn't have an add_character method")

func set_active_character(character: Node):
	active_character = character

func show_action_buttons(_character: Node):
	action_buttons.show()
	# You can customize this part to show different actions based on the character

func hide_action_buttons():
	action_buttons.hide()

func update_character_info():
# Update this method based on how your CharacterInfo node is structured
	if character_info.has_method("update_player_info") and active_character:
		character_info.update_player_info(active_character)
	if enemy_stats.has_method("update_enemy_info") and enemy:
		enemy_stats.update_enemy_stats(enemy) # Needs some fixing, The reason why the enemy has a player name.

func show_battle_result(result: String):
	battle_result_label.text = result
	battle_result_label.show()

# Health bar update functions
func update_player_health_bar():
	if active_character:
		player_health_bar.max_value = active_character.max_health
		player_health_bar.value = active_character.current_health
		player_health_bar.show()

func update_enemy_health_bar():
	if enemy:
		enemy_health_bar.max_value = enemy.max_health
		enemy_health_bar.value = enemy.current_health
		enemy_health_bar.show()

# Action button signals
func _on_attack_pressed():
	print("Attack button pressed")
	if enemy:
		print("Emitting action_selected signal with target: ", enemy.name)
		action_selected.emit("attack", enemy)
		hide_action_buttons()
	else:
		print("Error: No enemy target set")

func _on_defend_pressed():
	hide_action_buttons()
	action_selected.emit("defend", null)

func _on_skills_pressed():
	hide_action_buttons()
	action_selected.emit("skills", enemy)

func _on_items_pressed() -> void:
	hide_action_buttons()
	action_selected.emit("item", null)

func _on_run_pressed() -> void:
	pass # Replace with function body.


# Add other action button handlers as needed (Skills, Item, Run)

# Function to update all UI elements
func update_ui():
	update_character_info()
	update_player_health_bar()
	update_enemy_health_bar()

# Call this function when the battle starts or when switching to 3D
func prepare_for_3d():
# Create a new SubViewport
	var viewport = SubViewport.new()
	viewport.size = Vector2(1024, 600)  # Adjust size as needed
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# Move all children of this CanvasLayer to the SubViewport
	for child in get_children():
		remove_child(child)
		viewport.add_child(child)

	# Add the SubViewport to a new TextureRect
	var texture_rect = TextureRect.new()
	texture_rect.texture = viewport.get_texture()
	add_child(texture_rect)

# Now you can use this texture_rect in your 3D environment
# For example, you could assign its texture to a MeshInstance's material

# Remember to call prepare_for_3d() when you're ready to switch to 3D rendering
