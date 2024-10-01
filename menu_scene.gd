extends Node2D

var start_game_button: Button
var continue_game_button: Button
var exit_game_button: Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_game_button = $StartGameButton
	continue_game_button = $ContinueGameButton
	exit_game_button = $ExitGameButton

	# Подключаем сигналы нажатий кнопок
	start_game_button.connect("pressed", Callable(self, "_on_start_game_button_pressed"))
	continue_game_button.connect("pressed", Callable(self, "_on_continue_game_button_pressed"))
	exit_game_button.connect("pressed", Callable(self, "_on_exit_game_button_pressed"))

	# Проверяем наличие файла game.json в папке user://
	if not FileAccess.file_exists("user://game.json"):
		continue_game_button.disabled = true

# Функция при нажатии кнопки "Новая игра"
func _on_start_game_button_pressed() -> void:
	var dir = DirAccess.open("user://")
	if dir.file_exists("user://game.json"):
		dir.remove("user://game.json")
	get_tree().change_scene_to_file("res://novel_scene.tscn")

# Функция при нажатии кнопки "Продолжить игру"
func _on_continue_game_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_scene.tscn")

# Функция при нажатии кнопки "Выйти из игры"
func _on_exit_game_button_pressed() -> void:
	get_tree().quit()
