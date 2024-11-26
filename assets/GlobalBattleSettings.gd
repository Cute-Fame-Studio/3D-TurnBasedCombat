extends Node

# These variables do not NEED to have stuff filled out. 
# These variables would/can be a place to define what sound an animation player will play.
# It's goal is to not keep data hard to change, And keeping reuseability.
var Hit_Sound: AudioStream
var Critical_Sound: AudioStream
var Miss_Sound : AudioStream
var Escape_Sound: AudioStream
var Enemy_Defeat_Sound: AudioStream = null
var Boss_Defeat_Sound: AudioStream

enum Elements {
	Physical = 0,
	EARTH = 1,
	AIR = 2,
	FIRE = 3,
	WATER = 4,
	Magic = 5,
	ENDLIST
}

enum SkillTypes {
	Skills = 0,
	Healing = 1, #Placerholder.
	HealthAttacks = 2,
	ENDLIST
}

enum WeaponTypes {
	BareHands = 0,
	Sword = 1,
	Axe = 2,
	Bow = 3,
	Clae = 4,
	Undefined = 5,
	ENDLIST
}

enum ArmorTypes {
	RegularArmor = 0,
	LightArmor = 1,
	MagicArmor = 2,
	HeavyArmor = 3,
	MetalArmor = 4,
	ENDLIST
}
