#resource
extends Resource

@export var character_name: String = "Player"
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 5
@export var element: int = GlobalBattleSettings.Elements.Physical # Double Check, This may be broken. I cannot confirm
