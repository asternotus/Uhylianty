extends Node

var sound_player: AudioStreamPlayer

func _ready() -> void:
	if sound_player == null:
		sound_player = AudioStreamPlayer.new()
		add_child(sound_player)
	sound_player.autoplay = true

func play_sound(stream: AudioStream):
	if sound_player.stream != stream:
		sound_player.stream = stream
		sound_player.play()
	else:
		sound_player.play()

func stop_sound():
	sound_player.stop()
