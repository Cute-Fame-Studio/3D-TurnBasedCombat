## BattleAflictions
## Handles RPG Maker-style battle text formatting and display
## Used for damage, healing, and status effect messages during combat

class_name BattleAflictions

## Format damage/healing text with color codes and optional details
## Returns formatted BBCode string for Label display
static func format_damage_text(
	attacker: Battler,
	target: Battler,
	skill: Skill,
	damage: int,
	is_critical: bool = false,
	is_weakness: bool = false
) -> String:
	
	var text = ""
	
	# Attacker name and skill name
	if attacker:
		text += "[b]%s[/b]" % attacker.character_name
	
	if skill:
		text += " used [i]%s[/i]" % skill.skill_name
	else:
		text += " attacked"
	
	text += "!\n"
	
	# Target and damage/healing
	if target:
		text += "[b]%s[/b]" % target.character_name
	
	# Determine text color based on effect and element
	var color = get_element_color(skill.element if skill else 0)
	var damage_type = "took"
	
	if damage < 0:
		damage_type = "recovered"
		damage = abs(damage)
		color = Color.GREEN
	
	text += " %s [color=#%s]%d[/color] damage" % [
		damage_type,
		color.to_html(),
		damage
	]
	
	# Critical indicator
	if is_critical:
		text += " [i][color=#FFD700](CRITICAL!)[/color][/i]"
	
	# Weakness indicator
	if is_weakness:
		text += " [i][color=#FF69B4](weakness!)[/color][/i]"
	
	text += "!"
	
	return text

## Format healing text
static func format_heal_text(
	user: Battler,
	target: Battler,
	skill: Skill,
	healing: int
) -> String:
	
	var text = ""
	
	if user:
		text += "[b]%s[/b]" % user.character_name
	
	if skill:
		text += " used [i]%s[/i]" % skill.skill_name
	else:
		text += " used an item"
	
	text += "!\n"
	
	if target:
		text += "[b]%s[/b]" % target.character_name
	
	text += " [color=#00FF00]recovered %d HP[/color]!" % healing
	
	return text

## Format miss text
static func format_miss_text(
	attacker: Battler,
	target: Battler,
	skill: Skill
) -> String:
	
	var text = ""
	
	if attacker:
		text += "[b]%s[/b]" % attacker.character_name
	
	if skill:
		text += " used [i]%s[/i]" % skill.skill_name
	else:
		text += " attacked"
	
	text += "!\n"
	
	if target:
		text += "[b]%s[/b]" % target.character_name
	
	text += " [color=#808080](MISS!)[/color]"
	
	return text

## Format revive text
static func format_revive_text(
	user: Battler,
	target: Battler,
	skill: Skill
) -> String:
	
	var text = ""
	
	if user:
		text += "[b]%s[/b]" % user.character_name
	
	if skill:
		text += " used [i]%s[/i]" % skill.skill_name
	else:
		text += " used a revival item"
	
	text += "!\n"
	
	if target:
		text += "[b]%s[/b]" % target.character_name
	
	text += " [color=#FF69B4]was revived![/color]"
	
	return text

## Format status effect application text
static func format_state_text(
	_attacker: Battler,
	target: Battler,
	state: State
) -> String:
	
	var text = ""
	
	if target:
		text += "[b]%s[/b]" % target.character_name
	
	if state:
		text += " was afflicted with [i]%s[/i]" % state.state_name
	else:
		text += " was afflicted with a status effect"
	
	text += "!"
	
	return text

## Get color for element (BBCode hex format)
static func get_element_color(element_id: int) -> Color:
	var battle_settings = GlobalBattleSettings
	if battle_settings.has_meta("element_colors"):
		var colors = battle_settings.get_meta("element_colors")
		return colors.get(element_id, Color.WHITE)
	
	# Fallback to hardcoded if not in meta
	match element_id:
		GlobalBattleSettings.Elements.Physical:
			return Color.GRAY
		GlobalBattleSettings.Elements.EARTH:
			return Color.DARK_GOLDENROD
		GlobalBattleSettings.Elements.AIR:
			return Color.WHITE_SMOKE
		GlobalBattleSettings.Elements.FIRE:
			return Color.RED
		GlobalBattleSettings.Elements.WATER:
			return Color.SKY_BLUE
		GlobalBattleSettings.Elements.MAGIC:
			return Color.MAGENTA
		GlobalBattleSettings.Elements.NONE:
			return Color.WHITE
		_:
			return Color.WHITE
