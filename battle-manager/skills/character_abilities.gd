class_name CharacterAbilities extends Resource

@export var ability_name: String
@export var ability_description: String

@export var target_type: String # Ally or Enemy
@export var target_area: String # Single or Group

@export var number_value: float # damage or healing value
@export var damage_type: String # Physical, Magical, Healing, etc.
@export var anim_tree_name: String # name of animation to use
