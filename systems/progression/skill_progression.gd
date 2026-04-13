## Skill Progression Manager
## Handles skill unlocks based on character level
## Look for this file in: systems/progression/ folder

class_name SkillProgression
extends Node

## Get skills that should be unlocked at a specific level
static func get_skills_unlocked_at_level(all_skills: Array[Skill], target_level: int) -> Array[Skill]:
	var unlocked: Array[Skill] = []
	
	if not all_skills:
		return unlocked
	
	for skill in all_skills:
		if skill and skill.has_meta("unlock_level"):
			var unlock_level = skill.get_meta("unlock_level")
			if unlock_level == target_level:
				unlocked.append(skill)
	
	return unlocked

## Get all skills available up to a level
static func get_skills_available_up_to_level(all_skills: Array[Skill], max_level: int) -> Array[Skill]:
	var available: Array[Skill] = []
	
	if not all_skills:
		return available
	
	for skill in all_skills:
		if skill:
			var unlock_level = 1  # Default: available from start
			if skill.has_meta("unlock_level"):
				unlock_level = skill.get_meta("unlock_level")
			
			if unlock_level <= max_level:
				available.append(skill)
	
	return available

## Check if a battler should learn new skills on level up
static func check_level_up_skills(battler: Battler) -> Array[Skill]:
	if not battler or not battler.skill_node:
		return []
	
	var new_skills: Array[Skill] = []
	var current_level = battler.get_exp_stat().get_current_level() if battler.has_method("get_exp_stat") else 1
	
	# Get all available skills for this level
	var character_skills = battler.skill_node.character_skills if "character_skills" in battler.skill_node else []
	var just_unlocked = get_skills_unlocked_at_level(character_skills, current_level)
	
	# Add to battler's skill list if not already there
	for skill in just_unlocked:
		if skill and skill not in battler.skill_list:
			battler.skill_list.append(skill)
			new_skills.append(skill)
			print("%s learned %s!" % [battler.character_name, skill.skill_name])
	
	return new_skills
