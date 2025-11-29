class_name Troops
extends Resource


enum Formation {
	FRONT_ROW,
	TRIANGLE,
	CIRCLE_PLAYER,
	CUSTOM_MARKERS
}

@export var troop_name: String = ""
@export var troop_description: String = ""
@export var enemy_group: EnemyGroup = null  # Use EnemyGroup resource instead of Array[String]
@export var formation: Formation = Formation.FRONT_ROW
@export var damage_reduction: float = 1.0

# Helper function to get the array of loaded enemy scenes
func get_enemy_scenes() -> Array:
	if not enemy_group:
		push_warning("No enemy group assigned to troop: ", troop_name)
		return []
	
	var loaded_scenes: Array = []
	for scene in enemy_group.enemy_scenes:
		if scene:
			loaded_scenes.append(scene)
		else:
			push_warning("Null enemy scene in group: ", enemy_group.group_name)
	return loaded_scenes

# Get formation display name
func get_formation_name() -> String:
	match formation:
		Formation.FRONT_ROW:
			return "Front Row"
		Formation.TRIANGLE:
			return "Triangle"
		Formation.CIRCLE_PLAYER:
			return "Circle Around Player"
		Formation.CUSTOM_MARKERS:
			return "Custom Markers"
		_:
			return "Unknown"
