extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	if music_player == null:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
	music_player.autoplay = true

func play_music(stream: AudioStream):
	if music_player.stream != stream:
		music_player.stream = stream
		music_player.play()
	else:
		music_player.play()

func stop_music():
	music_player.stop()
