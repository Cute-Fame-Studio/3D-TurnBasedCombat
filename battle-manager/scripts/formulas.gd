class_name Formulas

# Element effectiveness matrix (Must use constant values, not enum references)
const ELEMENT_MATRIX = {
	0: { # Physical
		0: 1.0,  # Physical vs Physical
		1: 1.0,  # Physical vs Earth
		2: 1.0,  # Physical vs Air
		3: 1.0,  # Physical vs Fire
		4: 1.0,  # Physical vs Water
		5: 0.5   # Physical vs Magic
	},
	3: { # Fire
		0: 1.0,  # Fire vs Physical
		1: 2.0,  # Fire vs Earth
		2: 1.0,  # Fire vs Air
		4: 0.5,  # Fire vs Water
		5: 1.0   # Fire vs Magic
	},
	4: { # Water
		0: 1.0,  # Water vs Physical
		1: 0.5,  # Water vs Earth
		2: 1.0,  # Water vs Air
		3: 2.0,  # Water vs Fire
		5: 1.0   # Water vs Magic
	}
	# Add other elements as needed
}

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
## [Battler] [param attacker][br]
## [Battler]  [param target][br]
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
static func calculate_damage(attacker:Battler, target:Battler, skill:Skill) -> int:
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
