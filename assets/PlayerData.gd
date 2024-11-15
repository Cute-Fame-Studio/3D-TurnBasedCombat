#resource
extends Resource

@export var character_name: String = "Player"
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 5
@export var element: Elements

enum Elements 
{
    UNASPECTED = 0,
    EARTH = 1,
    AIR = 2,
    FIRE = 3,
    WATER = 4,
    ENDLIST
}