class_name EnemyGroup
extends Resource

## Resource class for storing a group/set of enemy scenes
## Used by the Troops resource to organize enemies into logical groups

@export var group_name: String = ""
@export var enemy_scenes: Array[PackedScene] = []  # Array of enemy scenes (PackedScene objects)
