class_name DamageNumber
extends RichTextLabel

@export var rise_speed:float = -25.0
@export_range(0.1, 10.0, 0.1) var frequency:float = 10.0
@export var amplitude:float = 1.0

@export var fade_time:float = 1.5
var time_alive:float = 0.0
var started_fade:bool = false
var value:int = 10

func _ready() -> void:
	text = "[b]" + str(value) + "[/b]"

func _process(delta:float) -> void:
	time_alive += delta
	position.y += delta * rise_speed
	position.x += get_oscillation(time_alive)
	if !started_fade:
		_fade_out()

func _fade_out() -> void:
	var fade_out_tween:Tween = get_tree().create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await fade_out_tween.finished
	call_deferred("queue_free")

func get_oscillation(time_alive:float) -> float:
	return sin(time_alive * frequency) * amplitude
