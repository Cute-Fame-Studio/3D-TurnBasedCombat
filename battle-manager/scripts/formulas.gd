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

static func calculate_damage(attacker, target, skill:Skill) -> int:
	var atk:float = float(attacker.stats.attack)
	var def:float = float(target.stats.defense)
	var damage:int = 1
	match GlobalBattleSettings.Global_Damage_Calc_Type:
		GlobalBattleSettings.Damage_Calc_Type.PKMN:
			damage = max(1, int((((((2.0 * attacker.exp_node.char_level) / 5.0 + 2) * skill.base_power * (atk / def)) / 50.0) + 2) * element_wheel(attacker.stats.element, target.stats.element)))
		GlobalBattleSettings.Damage_Calc_Type.DRGNQST:
			damage = max(1, int(((atk - (def / 2.0) + (((atk - (def/2.0) + 1.0) * randf_range(0, 255)) / 256.0)) / 4) * (skill.base_power / 50.0) * element_wheel(attacker.stats.element, target.stats.element)))
		_:
			damage = max(1, atk-def * (skill.base_power/50))
	return damage
