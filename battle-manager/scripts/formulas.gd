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
			damage = max(1, int((atk-def) * (skill.base_power/50.0) * element_wheel(skill.element, target.stats.element)))
	return damage

## Check if a target can be revived
## Returns true if target is defeated (current_health <= 0)
static func can_revive(target: Battler) -> bool:
	if not target:
		return false
	return target.is_defeated()

## Revive a defeated battler with specified health percentage
## Returns the amount of HP restored
static func apply_revive(target: Battler, hp_percent: int = 50) -> int:
	if not target:
		return 0
	
	# Clamp percentage to 1-100
	hp_percent = clampi(hp_percent, 1, 100)
	
	# Calculate HP to restore
	var hp_restored = int(target.max_health * (hp_percent / 100.0))
	hp_restored = maxi(hp_restored, 1)  # Minimum 1 HP
	
	# Apply healing
	target.current_health = hp_restored
	
	print("[Revive] %s revived with %d/%d HP" % [target.character_name, target.current_health, target.max_health])
	
	return hp_restored

## Calculate damage with difficulty scaling applied
static func calculate_damage_with_difficulty(attacker:Battler, target:Battler, skill:Skill, is_enemy_attacker: bool = false) -> int:
	var base_damage = calculate_damage(attacker, target, skill)
	
	# Apply difficulty multiplier based on whether it's player or enemy attacking
	if is_enemy_attacker:
		return DifficultyManager.apply_difficulty_to_damage(base_damage, "enemy_damage")
	else:
		return DifficultyManager.apply_difficulty_to_damage(base_damage, "player_damage")

## Apply difficulty scaling to defense
static func get_defense_with_difficulty(target: Battler, is_enemy_target: bool = false) -> float:
	var base_defense = float(target.defense)
	
	if is_enemy_target:
		var multiplier = DifficultyManager.get_difficulty_multiplier(DifficultyManager.get_active_difficulty(), "enemy_defense")
		return base_defense * multiplier
	
	return base_defense
