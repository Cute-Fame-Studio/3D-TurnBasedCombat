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
static func calculate_damage(attacker: Node, target: Node, skill: Skill) -> int:
	var base_damage = attacker.attack + skill.base_power
	
	# Get elemental multiplier
	var multiplier = 1.0
	if ELEMENT_MATRIX.has(skill.element) and ELEMENT_MATRIX[skill.element].has(target.stats.element):
		multiplier = ELEMENT_MATRIX[skill.element][target.stats.element]
	
	# Apply element multiplier and defense reduction
	var defense_reduction = target.defense * 0.5  # Reduce defense impact
	var final_damage = (base_damage - defense_reduction) * multiplier
	
	print("Element damage multiplier: %s vs %s = x%f" % [
		GlobalBattleSettings.Elements.keys()[skill.element],
		GlobalBattleSettings.Elements.keys()[target.stats.element],
		multiplier
	])
	
	return max(1, int(final_damage))  # Ensure minimum 1 damage
