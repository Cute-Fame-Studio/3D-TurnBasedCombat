class_name Formulas

static func physical_damage(attacker, target, damage) -> int:
	var offense = attacker.PlayerData.attack + damage
	var defense = target.PlayerData.defense
	var total_damage = max(0, offense-defense)
	return total_damage * element_wheel(attacker.PlayerData.element, target.PlayerData.element)

static func element_wheel(attack_element, defend_element) -> float:
	var multiplier = 1

	if attack_element == defend_element + 1:
		multiplier = 0.5
	else: if attack_element == defend_element - 1:
		multiplier = 2
		
	return multiplier
