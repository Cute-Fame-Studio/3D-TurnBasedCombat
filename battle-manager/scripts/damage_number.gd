class_name DamageNumber
extends RichTextLabel

@export var rise_speed:float = -25.0
@export_range(0.1, 10.0, 0.1) var frequency:float = 10.0
@export var amplitude:float = 1.0

@export var fade_time:float = 1.5

## Text Overlays for Different Damage Types
@export var critical_prefix: String = "[CRITICAL]"  ## Text shown before damage for crits
@export var critical_color: Color = Color.YELLOW
@export var miss_text: String = "MISS!"  ## Replacement text when attack misses
@export var miss_color: Color = Color.GRAY
@export var weakness_text: String = "[WEAKNESS!]"  ## Text shown before damage when weak
@export var weakness_color: Color = Color.MAGENTA
@export var unwinnable_text: String = ""  ## Hidden text for unwinnable battles (toggle on battler)

var time_alive:float = 0.0
var started_fade:bool = false
var value:int = 10
var is_critical: bool = false
var is_miss: bool = false
var is_weakness: bool = false

func _ready() -> void:
	# Don't show 0 damage numbers
    if value <= 0:
        queue_free()
        return
    
    # Build damage text with overlays
    var damage_text = ""
    
    if is_miss:
        damage_text = "[color=#%s]%s[/color]" % [miss_color.to_html(), miss_text]
    else:
        if is_critical:
            damage_text += "[color=#%s]%s[/color] " % [critical_color.to_html(), critical_prefix]
        if is_weakness:
            damage_text += "[color=#%s]%s[/color] " % [weakness_color.to_html(), weakness_text]
        damage_text += "[b][color=#FF0000]%d[/color][/b]" % value
    
    text = damage_text

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

func get_oscillation(time: float) -> float:
    return sin(time * frequency) * amplitude
