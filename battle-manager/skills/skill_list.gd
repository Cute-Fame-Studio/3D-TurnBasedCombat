class_name SkillList
extends Node

@export var character_skills: Array[Skill] = []
@export var hidden_skill_names: Array[String] = ["Attack"]  # Skills to hide from UI

func get_visible_skills() -> Array[Skill]:
	return character_skills.filter(func(skill): return not hidden_skill_names.has(skill.skill_name))

func get_skills() -> Array[Skill]:
	return character_skills
