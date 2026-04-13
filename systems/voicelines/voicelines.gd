## Character Voicelines System
## Attach to each battler's stats for context-based audio playback
## Look for this file in: systems/voicelines/ folder

class_name Voicelines
extends Resource

## Combat Event Sounds
@export var sound_on_battle_start: AudioStream
@export var sound_on_turn_start: AudioStream
@export var sound_on_attack: AudioStream
@export var sound_on_skill_use: AudioStream
@export var sound_on_take_damage: AudioStream
@export var sound_on_critical_hit: AudioStream
@export var sound_on_heal_received: AudioStream
@export var sound_on_revive: AudioStream
@export var sound_on_defeated: AudioStream
@export var sound_on_victory: AudioStream

## Cutscene/Custom Sounds - Map sound names to audio streams
@export var custom_sounds: Dictionary = {}  # {"cutscene_name": AudioStream, ...}

## Helper function to get sound by event
static func get_sound_for_event(voicelines: Voicelines, event: String) -> AudioStream:
	if not voicelines:
		return null
	
	match event.to_lower():
		"battle_start":
			return voicelines.sound_on_battle_start
		"turn_start":
			return voicelines.sound_on_turn_start
		"attack":
			return voicelines.sound_on_attack
		"skill":
			return voicelines.sound_on_skill_use
		"damage":
			return voicelines.sound_on_take_damage
		"critical":
			return voicelines.sound_on_critical_hit
		"heal":
			return voicelines.sound_on_heal_received
		"revive":
			return voicelines.sound_on_revive
		"defeated":
			return voicelines.sound_on_defeated
		"victory":
			return voicelines.sound_on_victory
		_:
			# Check custom sounds
			if voicelines.custom_sounds.has(event):
				return voicelines.custom_sounds[event]
			return null

## Play a sound for a battler with positional audio
## Instead of creating a new AudioStreamPlayer, searches for existing one
## or creates a AudioStreamPlayer3D for positional effects
static func play_sound(_battle_manager: BattleManager, battler: Battler, event: String, volume_db: float = 0.0) -> void:
	if not battler or not battler.stats:
		return
	
	var voicelines = battler.stats.voicelines if "voicelines" in battler.stats else null
	if not voicelines:
		return
	
	var sound = get_sound_for_event(voicelines, event)
	if not sound:
		return
	
	# Try to find existing AudioStreamPlayer in battler
	var player = battler.find_child("VoicelinePlayer", true, false) as AudioStreamPlayer
	
	# If not found, create a positional AudioStreamPlayer3D attached to battler
	if not player:
		player = AudioStreamPlayer3D.new()
		player.name = "VoicelinePlayer"
		player.bus = "Master"
		battler.add_child(player)
		player.position = Vector3(0, 2, 0)  # Position above battler for better audio
	
	# Update audio settings
	player.volume_db = volume_db
	player.stream = sound
	player.play()
	
	# Clean up after playback completes
	await player.finished
	# Don't remove the player, keep it for reuse next time
