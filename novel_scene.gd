extends Node2D

var time_manager: TimeManager

var background: Sprite2D
var date_label: Label
var dialog_avatar: Sprite2D
var dialog_label: Label
var blackout: ColorRect
var skip_story_button: Button

var story_data = []
var current_block = 0
var typing = false
var full_text = ""  # Полный текст блока
var stop_typing = false  # Флаг для остановки печати

var without_story = false

# Вызывается при входе узла в дерево сцены
func _ready() -> void:
	time_manager = GameTimeManager
	
	background = $Background
	date_label = $DateLabel
	dialog_avatar = $DialogAvatar
	dialog_label = $DialogLabel
	blackout = $Blackout
	skip_story_button = $SkipStoryButton
	
	skip_story_button.visible = false
	
	var file_name = ""
	
	# Имя файла на основе даты
	if time_manager.is_lose == "":
		if time_manager.current_date == null:
			file_name = "01.06.2022.txt"
		else:
			file_name = time_manager.get_default_format_date() + ".txt"
	else:
		file_name = time_manager.is_lose
	
	# Проверяем, существует ли файл
	if FileAccess.file_exists("res://stories/" + file_name) and without_story == false:
	
		# Чтение файла истории
		parse_story_file(file_name)

		var block = story_data[current_block]
		if block.has("date"):
			date_label.text = block["date"]
		
		skip_story_button.visible = true
		skip_story_button.connect("pressed", Callable(self, "_on_skip_story_button_pressed"))
		
		# Показываем первый блок истории
		show_next_block()
	
		await fade_out()
		
	else:
		call_deferred("load_main_scene")

# Функция при нажатии кнопки "Пропустить историю"
func _on_skip_story_button_pressed() -> void:
	MusicManager.stop_music()
	if time_manager.is_lose != "":
		var dir = DirAccess.open("user://")
		if dir.file_exists("user://game.json"):
			dir.remove("user://game.json")
		
		# Переход в меню при проигрыше
		get_tree().change_scene_to_file("res://menu_scene.tscn")
		time_manager.is_lose = ""
		time_manager.current_date = null
	else:
		# Переход к основной сцене
		get_tree().change_scene_to_file("res://main_scene.tscn")
	

# Функция для отложенной смены сцены
func load_main_scene():
	get_tree().change_scene_to_file("res://main_scene.tscn")

# Чтение и парсинг файла с историей
func parse_story_file(file_name: String) -> void:
	var file = FileAccess.open("res://stories/" + file_name, FileAccess.READ)
	if file:
		var block = {}
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line == "":  # Пустая строка означает конец блока
				story_data.append(block)
				block = {}  # Начинаем новый блок
			elif line.begins_with("date:"):
				block["date"] = line.replace("date:", "").strip_edges()
			elif line.begins_with("image:"):
				block["image"] = line.replace("image:", "").strip_edges()
			elif line.begins_with("background:"):
				block["background"] = line.replace("background:", "").strip_edges()
			elif line.begins_with("music:"):
				block["music"] = line.replace("music:", "").strip_edges()
			elif line.begins_with("sound:"):
				block["sound"] = line.replace("sound:", "").strip_edges()
			elif line.begins_with("description:"):
				block["description"] = line.replace("description:", "").strip_edges()
		# Добавляем последний блок, если он не пуст
		if block:
			story_data.append(block)
		file.close()

# Показываем следующий блок истории
func show_next_block() -> void:
	if current_block >= story_data.size():
		if time_manager.is_lose != "":
			var dir = DirAccess.open("user://")
			if dir.file_exists("user://game.json"):
				dir.remove("user://game.json")
				
			get_tree().change_scene_to_file("res://menu_scene.tscn")
			time_manager.is_lose = ""
			time_manager.current_date = null
			
		else:
			get_tree().change_scene_to_file("res://main_scene.tscn")
		
		return

	var block = story_data[current_block]
	current_block += 1

	# Устанавливаем фон
	if block.has("background"):
		background.texture = load("res://backs/" + block["background"])
		
	# Устанавливаем музыку
	if block.has("music"):
		if block["music"] == "STOP":
			MusicManager.stop_music()
		else:
			var audio_stream = load("res://" + block["music"]) as AudioStream
			if not MusicManager.music_player.playing:
				audio_stream.loop = true
				MusicManager.play_music(audio_stream)
	
	# Устанавливаем звук
	if block.has("sound"):
		if block["sound"] == "STOP":
			SoundManager.stop_sound()
		else:
			var sound_audio_stream = load("res://" + block["sound"]) as AudioStream
			SoundManager.play_sound(sound_audio_stream)
	
	# Устанавливаем аватар
	if block.has("image") and block["image"] != "transparent":
		dialog_avatar.texture = load("res://" + block["image"])
	else:
		dialog_avatar.texture = null  # Прозрачный аватар
	
	# Печатаем текст описания
	if block.has("description"):
		full_text = block["description"]
		type_text(dialog_label, full_text)

# Печать текста по символу
func type_text(label: Label, text: String, speed: float = 0.05) -> void:
	typing = true
	stop_typing = false  # Сбрасываем флаг остановки
	label.text = ""
	var current_text = ""
	for char in text:
		if stop_typing:  # Останавливаем печать текста, если флаг установлен
			break
		current_text += char
		label.text = current_text
		await get_tree().create_timer(speed).timeout
	typing = false

# Обработка нажатий мышки
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if typing:  # Если текст ещё печатается, сразу показать его полностью
			stop_typing = true  # Устанавливаем флаг для остановки печати
			dialog_label.text = full_text  # Показать весь текст
			typing = false
		else:  # Если текст полностью напечатан, показать следующий блок
			show_next_block()

func fade_in() -> void:
	blackout.visible = true
	var current_alpha = 0.0
	while current_alpha < 1.0:
		current_alpha += 0.05
		blackout.set_color(Color(0, 0, 0, current_alpha))
		await get_tree().create_timer(0.05).timeout

func fade_out() -> void:
	var current_alpha = 1.0
	while current_alpha > 0.0:
		current_alpha -= 0.05
		blackout.set_color(Color(0, 0, 0, current_alpha))
		await get_tree().create_timer(0.05).timeout
	blackout.visible = false
