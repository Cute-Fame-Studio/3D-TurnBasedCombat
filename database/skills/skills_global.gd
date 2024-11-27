extends Resource

@export var color := ""
@export var tags := ""
@export var type := ""
@export var icon : Resource
@export var animation_name := ""
@export var critical_rate : int
@export var hit_chance : int
@export var target := ""
@export var description := ""
@export var sp : int
@export var hp : int
@export var element := ""
# Don't forget captilization when defining enum's.
@export var skill_type : int = GlobalBattleSettings.SkillTypes.SKILLS
