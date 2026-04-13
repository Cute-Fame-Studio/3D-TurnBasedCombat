## BattleTextDisplay
## Manages the display of battle affliction text with animations
## Shows RPG Maker-style damage/heal/status messages with formatting

class_name BattleTextDisplay
extends RichTextLabel

# Lazy-load BattleAflictions module for text formatting
var _battle_afflictions = null

func _get_afflictions():
	if _battle_afflictions == null:
		_battle_afflictions = load("res://battle-manager/scripts/battle_afflictions.gd")
	return _battle_afflictions

## Export controls for text display options
@export var show_damage_dealt: bool = true
@export var show_skill_name: bool = true
@export var show_weakness_indicator: bool = true
@export var use_color_formatting: bool = true

## Display duration multiplier (capped at 0.5-7 seconds: 25%-350%)
## Display time = 2.0 * (duration_multiplier / 100.0), clamped
@export_range(25, 350, 5) var duration_multiplier: int = 100  ## Percentage of base duration

## Calculated display duration based on multiplier
var display_duration: float = 2.0

## Fade duration (in seconds)
@export var fade_duration: float = 0.5

var tween: Tween

func _ready():
	# Start with transparent text
	modulate.a = 0.0
	text = ""
	
	# Calculate capped display duration based on multiplier
	display_duration = 2.0 * (float(duration_multiplier) / 100.0)
	display_duration = clampf(display_duration, 0.5, 7.0)  # Cap at 0.5-7 seconds

## Display battle text with fade in/out animation
func display_battle_text(formatted_text: String) -> void:
	# Kill previous tween if running
	if tween:
		tween.kill()
	
	# Set text
	text = formatted_text
	
	# Create new tween for fade in, display, fade out
	tween = create_tween()
	tween.set_parallel(false)  # Sequential animations
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	
	# Wait for display duration
	tween.tween_callback(func(): await get_tree().create_timer(display_duration).timeout)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	
	# Clear text after fade
	tween.tween_callback(func(): text = "")

## Display damage text
func show_damage(
	attacker: Battler,
	target: Battler,
	skill: Skill,
	damage: int,
	is_critical: bool = false,
	is_weakness: bool = false
) -> void:
	var afflictions = _get_afflictions()
	var formatted = afflictions.format_damage_text(
		attacker,
		target,
		skill,
		damage,
		is_critical,
		is_weakness
	)
	display_battle_text(formatted)

## Display healing text
func show_healing(
	user: Battler,
	target: Battler,
	skill: Skill,
	healing: int
) -> void:
	var afflictions = _get_afflictions()
	var formatted = afflictions.format_heal_text(user, target, skill, healing)
	display_battle_text(formatted)

## Display miss text
func show_miss(
	attacker: Battler,
	target: Battler,
	skill: Skill
) -> void:
	var afflictions = _get_afflictions()
	var formatted = afflictions.format_miss_text(attacker, target, skill)
	display_battle_text(formatted)

## Display revive text
func show_revive(
	user: Battler,
	target: Battler,
	skill: Skill
) -> void:
	var afflictions = _get_afflictions()
	var formatted = afflictions.format_revive_text(user, target, skill)
	display_battle_text(formatted)

## Display state application text
func show_state(
	attacker: Battler,
	target: Battler,
	state: State
) -> void:
	var afflictions = _get_afflictions()
	var formatted = afflictions.format_state_text(attacker, target, state)
	display_battle_text(formatted)
