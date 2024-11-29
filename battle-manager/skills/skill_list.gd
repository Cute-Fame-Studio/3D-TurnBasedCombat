class_name SkillList extends Node

@export var default_skill: Array[Resource] = []

var character_skills: Array[Resource] = []

func _ready():
	create_skill_list()

func create_skill_list():
	if character_skills.size() != 0:
		return
	if default_skill == null || default_skill.size() <= 0:
		return
	
	for skill in default_skill:
		character_skills.append(ResourceLoader.load(skill.resource_path))

func get_skills():
	return character_skills
