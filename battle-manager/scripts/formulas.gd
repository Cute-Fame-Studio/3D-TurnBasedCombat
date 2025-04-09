class_name Formulas

static func physical_damage(attacker, target, damage) -> int:
	var offense = attacker.stats.attack + damage
	var defense = attacker.stats.defense
	var total_damage = max(0, offense-defense)
	return total_damage * element_wheel(attacker.stats.element, target.stats.element)

static func element_wheel(attack_element, defend_element) -> float:
	var multiplier = 1

	if attack_element == defend_element + 1:
		multiplier = 0.5
	else: if attack_element == defend_element - 1:
		multiplier = 2
		
	return multiplier

## Calculates damage based on stats, skill, and designated global damage calculation type.[br]
## [br]
## [color=cyan]Function Parameters:[/color][br]
## [Ally] or [Enemy] [param attacker][br]
## [Ally] or [Enemy]  [param target][br]
## [Skill]  [param skill][br]
## [br]
## [color=cyan]Global Damage Calculation Types:[/color][br]
## [b]PKMN[/b] - Damage calculation similar to Gen 3+ Pokemon.[br]
## [url=https://bulbapedia.bulbagarden.net/wiki/Damage#Generation_III]Pokemon Gen 3 Damage Calculation[/url][br]
## [code]((((2.0 * attacker.exp_node.char_level) / 5.0 + 2) * skill.base_power * (atk / def)) / 50.0) + 2[/code][br]
## [br]
## [b]DRGNQST[/b] - Damage calculation similar to Dragon Quest.[br]
## [url=https://dragonquestcosmos.fandom.com/wiki/Formulas#Damage_Calculation]Dragon Quest Damage Calculation[/url][br]
## [code]((atk - (def / 2.0) + (((atk - (def/2.0) + 1.0) * randf_range(0, 255)) / 256.0)) / 4) * (skill.base_power / 50.0)[/code][br]
## [br]
## Default damage calculation.[br]
## [code](attacker.attack - target.defense) * (skill.power / 50)[/code][br]
## [br]
## [color=orange]!All listed formulas have their value multiplied by the type[br]
## effectiveness value returned by [method element_wheel].[br]
## [color=red]!!Minimum value that can be returned by all formulas is [b]1[/b].[/color][br]
static func calculate_damage(attacker, target, skill:Skill) -> int:
	var atk:float = float(attacker.stats.attack)
	var def:float = float(target.stats.defense)
	var damage:int = 1
	match GlobalBattleSettings.Global_Damage_Calc_Type:
		GlobalBattleSettings.Damage_Calc_Type.PKMN:
			damage = max(1, int((((((2.0 * attacker.exp_node.char_level) / 5.0 + 2) * skill.base_power * (atk / def)) / 50.0) + 2) * element_wheel(skill.element, target.stats.element)))
		GlobalBattleSettings.Damage_Calc_Type.DRGNQST:
			damage = max(1, int(((atk - (def / 2.0) + (((atk - (def/2.0) + 1.0) * randf_range(0, 255)) / 256.0)) / 4) * (skill.base_power / 50.0) * element_wheel(skill.element, target.stats.element)))
		_:
			damage = max(1, atk-def * (skill.base_power/50) * element_wheel(skill.element, target.stats.element))
	return damage
