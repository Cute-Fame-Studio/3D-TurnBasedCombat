extends Node

# Must be set/used to get player turn.
var activeBattler

# These variables do not NEED to have stuff filled out. 
# These variables would/can be a place to define what sound an animation player will play.
# It's goal is to not keep data hard to change, And keeping reuseability.
var Hit_Sound: AudioStream
var Critical_Sound: AudioStream
var Miss_Sound : AudioStream
var Escape_Sound: AudioStream
var Enemy_Defeat_Sound: AudioStream = null
var Boss_Defeat_Sound: AudioStream = null

var ally_party: int = 0

enum Elements {
	Physical = 0,
	EARTH = 1,
	AIR = 2,
	FIRE = 3,
	WATER = 4,
	MAGIC = 5,
	ENDLIST}

enum SkillTypes {
	SKILLS = 0,
	HEALING = 1, #Placerholder.
	HEALTHREDUCTIONATTACKS = 2,
	ENDLIST}

enum WeaponTypes {
	HANDS = 0,
	SWORD = 1,
	AXE = 2,
	BOW = 3,
	CLAWS = 4,
	UNDEFINED = 5,
	ENDLIST}

enum ArmorTypes {
	REGULARARMOR = 0,
	LIGHTARMOR = 1,
	MAGICARMOR = 2,
	HEAVYARMOR = 3,
	METALARMOR = 4,
	ENDLIST}

enum Difficulties {
	EASY = 0,
	NORMAL = 1,
	HARD = 2,
	ENDLIST}

# Start Functions down here.


# Find the first battler, This may be set to allow anyone to go first later. For situations
# Where they get hit first before battle.
func set_active_battler(character):
	activeBattler = character
