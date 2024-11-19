class_name Formulas

static func physical_damage(attacker, target, damage) -> int:
	var offense = attacker.PlayerData.attack + damage
	var defense = target.PlayerData.defense
	var total_damage = min(0, defense - offense)
	return total_damage * element_wheel(attacker.PlayerData.element, target.PlayerData.element, attacker.PlayerData.Elements)

static func element_wheel(attack_element, defend_element, element_list) -> float:
	var multiplier = 1
	
	var next_element = attack_element + 1
	var prev_element = attack_element - 1
	
	if next_element == element_list.ENDLIST:
		next_element = 1
	if prev_element == 0:
		prev_element = element_list.ENDLIST - 1
	
	if prev_element == defend_element:
		multiplier = 0.5
	else: if next_element == defend_element:
		multiplier = 2
		
	return multiplier
