@tool
class_name BattlerStats
extends Resource

@export var character_name: String = "Player" ## Fill in this variable as soon as possible, This will be used when mentioning the character
@export var thumbnail: Texture2D = preload("res://Placeholder.svg") ## Portrait shown in battle results UI.

@export_group("Battle Rewards")
@export var exp_reward: int = 100 ## EXP granted when this battler is defeated.
@export var cash_reward: int = 10 ## Cash granted when this battler is defeated.
@export var item_drops: Array[EnemyDrop] = [] ## Optional item drops with per-drop percentage chance (EnemyDrop resources).

## LEVEL-FOCUSED PROGRESSION SYSTEM
## Each battler has a level that determines their stats via multipliers
## Stat = base_stat + (level - 1) * stat_multiplier
@export var level: int = 1 ## Character level (determines stat scaling)

@export_group("Base Stats (at Level 1)")
@export var max_health: int = 100 ## Health is used to make sure character's take longer to be downed.
@export var max_sp: int = 100 ## SP is required for many skills, Such as healing or damaging.
@export var attack: int = 10 ## Attack will increase the amount of base damage when peforming any skill.
@export var defense: int = 5 ## Defense is another way to reduce damage. (Added to the damage intake)
@export var agility: int = 5 ## Agility of the character (affects speed and evasion)

@export_group("Stat Multipliers (per level)")
## Growth per level: new_stat = base_stat + (level - 1) * multiplier
@export var health_multiplier: int = 15 ## Health gain per level
@export var sp_multiplier: int = 5 ## SP gain per level
@export var attack_multiplier: int = 2 ## Attack gain per level
@export var defense_multiplier: int = 1 ## Defense gain per level
@export var agility_multiplier: int = 1 ## Agility gain per level

@export_group("Other Stats")
@export var sp_regen: int = 5  ## Amount of SP recovered per turn
@export var element: int = GlobalBattleSettings.Elements.Physical ## Elements has their own docs file.

## Voicelines and Audio
@export var voicelines: Voicelines  ## Character voicelines for combat events
