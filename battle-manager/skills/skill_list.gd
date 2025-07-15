class_name SkillList
extends Node

@export var character_skills: Array[Skill] = []

func get_skills() -> Array[Skill]:
	return character_skills
