class_name BattlerStats
extends Resource

@export var character_name: String = "Player"
@export var max_health: int = 100
@export var max_sp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 5

@export var sp_regen: int = 5  # Amount of SP recovered per turn
@export var element: int = GlobalBattleSettings.Elements.Physical
