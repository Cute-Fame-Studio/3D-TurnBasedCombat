class_name BattleHud
extends CanvasLayer

signal action_selected(action: String, target, skill:Skill)

@export var skill_button_scene: PackedScene
@onready var skill_container = $Control/Skills/ScrollContainer/BoxContainer

@onready var action_buttons: BoxContainer = $Control/ActionButtons
@onready var ally_stats: BoxContainer = $Control/Players/AllAllies/AllyStats
@onready var enemy_stats: BoxContainer = $Control/Enemies/AllEnemies/EnemyStats
@onready var battle_result = $Control/BattleResults
@onready var battle_result_label: Label = $Control/BattleResults/BattleResultLabel # I personally think this should be removed.
@onready var skill_select: Control = $Control/Skills

var activeBattler: Node = null
var enemy: Node = null

var active_allies = []
var active_enemies = []

# Health bar-related nodes
@onready var player_health_bar = $Control/Players/AllAllies/AllyStats/PlayerHealthBar
@onready var enemy_health_bar = $Control/Enemies/AllEnemies/EnemyStats/EnemyHealthBar

# Add SP bar reference
@onready var player_sp_bar = $Control/Players/AllAllies/AllyStats/PlayerSPBar

func _ready():
	print("Inside BattleHUD _ready()")
	skill_select.visible = false
	battle_result_label.hide()
	hide_action_buttons()

	# Initialize health bars
	if player_health_bar and enemy_health_bar:
		player_health_bar.value = 0
		enemy_health_bar.value = 0

func on_start_combat(enemy_node: Node):
	enemy = enemy_node
	update_health_bars()

func on_add_character(character: Node):
	if character.is_in_group("players"):
		if ally_stats.has_method("update_player_stats"):
			ally_stats.update_player_stats(character)
	else:
		if ally_stats.has_method("update_enemy_stats"):
			enemy_stats.update_enemy_stats(character)

# Modify update_health_bars
func update_health_bars():
	for i in range(active_allies.size()):
		var ally = active_allies[i]
		var container = $Control/Players/AllAllies.get_child(i)
		container.update_character_info(ally)
		
	for i in range(active_enemies.size()):
		var target_enemy = active_enemies[i]
		var container = $Control/Enemies/AllEnemies.get_child(i)
		container.update_character_info(target_enemy)

func set_activebattler(character: Node):
	activeBattler = character

func show_action_buttons(_character: Node):
	action_buttons.show()
	# You can customize this part to show different actions based on the character

func hide_action_buttons():
	action_buttons.hide()

func update_character_info():
	if enemy and enemy_stats:
		enemy_stats.update_enemy_stats(enemy)
		
	if ally_stats.has_method("update_player_stats") and activeBattler:
		ally_stats.update_player_stats(activeBattler)
	if ally_stats.has_method("update_enemy_stats") and enemy:
		enemy_stats.update_enemy_stats(enemy)

func show_battle_result(result: String):
	battle_result_label.text = result
	battle_result_label.show()

# Health bar update functions
func update_player_health_bar():
	if activeBattler:
		# Health bar
		player_health_bar.max_value = activeBattler.max_health
		player_health_bar.value = activeBattler.current_health
		player_health_bar.show()
		
		# SP bar
		player_sp_bar.max_value = activeBattler.max_sp
		player_sp_bar.value = activeBattler.current_sp
		player_sp_bar.show()

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
		action_selected.emit("attack", enemy, null)
		hide_action_buttons()
	else:
		print("Error: No enemy target set")

func _on_defend_pressed():
	hide_action_buttons()
	action_selected.emit("defend", null, null)

func setup_skill_list(battler: Node) -> void:
	# Clear existing skill buttons
	for child in skill_container.get_children():
		child.queue_free()
	
	# Create new skill buttons
	if battler.skill_list.size() > 0:
		for skill in battler.skill_list:
			var button = skill_button_scene.instantiate()
			skill_container.add_child(button)
			# Pass the skill resource directly since it should already be a Skill resource
			button.setup(skill)
			button.skill_selected.connect(_on_skill_selected)

func _on_skill_selected(skill: Resource) -> void:
	skill_select.visible = false
	action_selected.emit("skill", enemy, skill)

func _on_skills_pressed() -> void:
	hide_action_buttons()
	setup_skill_list(activeBattler)
	skill_select.visible = true

func _on_items_pressed() -> void:
	hide_action_buttons()
	action_selected.emit("item", null, null)

func _on_run_pressed() -> void:
	hide_action_buttons()
	action_selected.emit("run", null, null)

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
