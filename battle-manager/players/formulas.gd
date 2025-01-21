class_name Formulas

static func physical_damage(attacker, target, damage) -> int:
	var offense = attacker.PlayerData.attack + damage
	var defense = target.PlayerData.defense
	var total_damage = max(1, offense-defense)
	return total_damage * element_wheel(attacker.PlayerData.element, target.PlayerData.element)

static func element_wheel(attack_element, defend_element) -> float:
	var multiplier = 1

	if attack_element == defend_element + 1:
		multiplier = 0.5
	else: if attack_element == defend_element - 1:
		multiplier = 2
		
	return multiplier

static func calculate_damage(attacker, target, attack:CharacterAbilities) -> int:
	var atk:float = float(attacker.PlayerData.attack)
	var def:float = float(target.PlayerData.defense)
	var damage:int = 1
	match GlobalBattleSettings.Global_Damage_Calc_Type:
		GlobalBattleSettings.Damage_Calc_Type.PKMN:
			damage = max(1, int((((((2.0 * attacker.exp_node.char_level) / 5.0 + 2) * attack.number_value * (atk / def)) / 50.0) + 2) * element_wheel(attacker.PlayerData.element, target.PlayerData.element)))
		GlobalBattleSettings.Damage_Calc_Type.DRGNQST:
			damage = max(1, int(((atk - (def / 2.0) + (((atk - (def/2.0) + 1.0) * randf_range(0, 255)) / 256.0)) / 4) * (attack.number_value / 50.0) * element_wheel(attacker.PlayerData.element, target.PlayerData.element)))
		_:
			max(1, atk-def * (attack.number_value/50))
	return damage
