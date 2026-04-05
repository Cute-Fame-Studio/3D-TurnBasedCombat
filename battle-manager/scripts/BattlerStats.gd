@tool
class_name BattlerStats
extends Resource

@export var character_name: String = "Player" ## Fill in this variable as soon as possible, This will be used when mentioning the character
@export var max_health: int = 100 ## Health is used to make sure character's take longer to be downed.
@export var max_sp: int = 100 ## SP is required for many skills, Such as healing or damaging.
@export var attack: int = 10 ## Attack will increase the amount of base damage when peforming any skill.
@export var defense: int = 5 ## Defense is another way to reduce damage. (Added to the damage intake)
@export var agility: int = 5 ## Agility of the character (affects speed and evasion)

@export var sp_regen: int = 5  ## Amount of SP recovered per turn
@export var element: int = GlobalBattleSettings.Elements.Physical ## Elements has their own docs file.
