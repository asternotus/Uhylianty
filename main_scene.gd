extends Node2D

# Константы для настройки баланса
const DEFAULT_TYPE_SPEED: float = 0.01
const ALARM_PROBABILITY_VALUE: float = 0.3

const NIGHT_EVENT_WAIT_TIME: float = 2.5

const MOOD_INCREASE_TALK: int = 2
const MOOD_DECREASE_PER_DAY_MIN: int = 1
const MOOD_DECREASE_PER_DAY_MAX: int = 1

const SUPPORT_MOOD_INCREASE: int = 3

const AIM_PROGRESS_SEARCH: int = 1

const MONEY_EARN_MIN: int = 1000
const MONEY_EARN_MAX: int = 3000
const DAILY_MONEY_LOSS_MIN: int = 1000
const DAILY_MONEY_LOSS_MAX: int = 3000
const WORK_PROBABILITY: float = 0.8

const FOOD_INCREASE_MIN: int = 3
const FOOD_INCREASE_MAX: int = 3
const FOOD_COST_MIN: int = 500
const FOOD_COST_MAX: int = 500
const FOOD_BUY_PROBABILITY: float = 0.8

const MEDICINES_COST_MIN: int = 1000
const MEDICINES_COST_MAX: int = 1000
const MEDICINES_BUY_VALUE = 1
const MEDICINES_FOR_HEALING = 1
const MEDICINES_BUY_PROBABILITY: float = 0.8

const HOUSE_REPAIR_COST_MIN: int = 1000
const HOUSE_REPAIR_COST_MAX: int = 1000
const HOUSE_REPAIR_VALUE: int = 1
const HOUSE_REPAIR_PROBABILITY: float = 0.8

const HOUSE_DAMAGE_MIN: int = 1
const HOUSE_DAMAGE_MAX: int = 3

const TALK_TIME: int = 2
const SEARCH_TIME: int = 2
const WORK_TIME: int = 2
const BUY_FOOD_TIME: int = 2
const BUY_MEDICINES_TIME: int = 2
const HOUSE_REPAIR_TIME: int = 2
const HEAL_TIME: int = 2

const END_DAY_TIME: int = 22

const MOOD_THRESHOLD_DEATH: int = 0
const HOUSE_THRESHOLD_DEATH: int = 0
const FOOD_THRESHOLD_DEATH: int = 0
const MONEY_THRESHOLD_DEATH: int = 0

var time_manager: TimeManager
var date_label: Label

var money: int
var food: int
var house: int
var medicines: int

var search_info_progress: int
var hold_money_progress: int
var leave_country_progress: int

var aim_description_label: Label

var day_remains

var bars_container: HBoxContainer

var money_label: Label
var food_label: Label
var house_label: Label
var medicines_label: Label

var aim_progress_bar: ProgressBar

var night_label: Label
var event_night_label: Label

var buttons_holder: GridContainer

var blackout: ColorRect

var dialog_avatar: Sprite2D
var dialog_label: RichTextLabel

var reactions

var inna
var max
var kostya

var friends = [inna, max, kostya]

var game_events
var game_events_manager = load("res://game_events_manager.gd").new()

var alarm_icon: Sprite2D
var blackout_icon: Sprite2D

var night_text

func _ready() -> void:
	time_manager = GameTimeManager
	date_label = $DateLabel
	bars_container = $BarsContainer
	
	money_label = $MoneyLabel
	food_label = $FoodLabel
	house_label = $HouseLabel
	medicines_label = $MedicinesLabel
	
	aim_description_label = $AimDescriptionLabel
	aim_progress_bar = $AimProgressBar
	
	night_label = $NightLabel
	event_night_label = $EventNightLabel
	
	buttons_holder = $ButtonsHolder
	
	blackout = $Blackout
	
	dialog_avatar = $DialogAvatar
	dialog_label = $DialogLabel
	
	reactions = load("res://reactions.gd").new().reactions
	
	alarm_icon = $AlarmIcon
	blackout_icon = $BlackoutIcon
	
	alarm_icon.visible = false
	blackout_icon.visible = false
	
	# ЗАПУСКАТЬ ПРИ ИЗМЕНЕНИИ СТРУКТУРЫ game.json
	# delete_game_data()
	night_text = ""
	
	copy_game_data_to_user()
	load_game_data()
	
	var audio_stream = load("res://music/main_theme.mp3") as AudioStream
	if not MusicManager.music_player.playing:
		audio_stream.loop = true
		MusicManager.play_music(audio_stream)

	for friend in friends:
		var progress_bar = aim_progress_bar.duplicate()
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND
		progress_bar.value = friend.mood
		
		progress_bar.min_value = 0
		progress_bar.max_value = 10
		
		progress_bar.custom_minimum_size = Vector2(170, 0) 
		
		bars_container.add_child(progress_bar)
		
		var btn = TextureButton.new()
		btn.texture_normal = load(friend.image_path)
		btn.size_flags_horizontal = Control.SIZE_EXPAND
		
		btn.connect("pressed", Callable(self, "_on_character_button_pressed").bind(friend))
		
		buttons_holder.add_child(btn)
	
	game_events = game_events_manager.generate_events(time_manager.current_date)
	
	#for ev in game_events:
		#print(ev.event_type)
		#print(ev.start_time)
		#print(ev.duration)

	update_ui()
	
	await fade_out()
	
	check_friends_life()
	is_lose()

func update_ui():	
	money_label.text = str(money) + " грн."
	food_label.text = str(food)
	house_label.text = str(house)
	medicines_label.text = str(medicines)
	
	if search_info_progress < 100:
		aim_description_label.text = "Найти информацию"
		aim_progress_bar.value = search_info_progress

	elif hold_money_progress < 100:
		aim_description_label.text = "Собрать 100 000 грн."
		hold_money_progress = (money / 100000.0) * 100
		aim_progress_bar.value = hold_money_progress
		
		for friend in friends:
			if "Искать информацию" in friend.actions:
				friend.actions.erase("Искать информацию")
					
		
	elif leave_country_progress < 100:
		aim_description_label.text = "Покинуть страну"
		aim_progress_bar.value = leave_country_progress

		for friend in friends:
			if "Искать информацию" in friend.actions:
				friend.actions.remove("Искать информацию")

		for friend in friends:
			if "Готовиться к выезду" not in friend.actions:
				friend.actions.append("Готовиться к выезду")

	date_label.text = time_manager.get_current_date_time()

	var index = 0
	
	for child in bars_container.get_children():
		if child is ProgressBar and index < friends.size():
			child.value = friends[index].mood
			index += 1
			
	# Проход по каждому персонажу и скрытие их элементов, если они не живы
	for i in range(friends.size()):
		var friend = friends[i]
		
		# Если персонаж болен, делаем ему другой набор действий. Также учитываем, есть ли лекарство.
		if friend.is_sick:
			if medicines > 0:
				friend.actions = friend.actions_sick
			else:
				friend.actions = []
		else:
			friend.actions = friend.default_actions
		
		# Если персонаж не жив, делаем его элементы прозрачными и отключаем мышиное взаимодействие
		if not friend.is_alive:
			# Прозрачные элементы в bars_container и buttons_holder по индексу i
			if i < bars_container.get_child_count():
				var bar_child = bars_container.get_child(i)
				bar_child.modulate = Color(1, 1, 1, 0)  # Прозрачный
				bar_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
			if i < buttons_holder.get_child_count():
				var button_child = buttons_holder.get_child(i)
				button_child.modulate = Color(1, 1, 1, 0)  # Прозрачный
				button_child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_character_button_pressed(friend: Character) -> void:
	var popup = PopupMenu.new()

	for action in friend.actions:
		popup.add_item(action)

	popup.connect("id_pressed", Callable(self, "_on_action_selected").bind(friend))

	var mouse_pos = get_viewport().get_mouse_position()
	popup.set_position(mouse_pos)

	add_child(popup)
	popup.popup()

func _on_action_selected(action_id: int, friend: Character) -> void:
	dialog_label.bbcode_enabled = true
	var selected_action = friend.actions[action_id]
	var reaction_text = ""
	var fail = false

	match selected_action:
		"Поговорить":
			friend.increase_mood(MOOD_INCREASE_TALK)
			add_hours(TALK_TIME)
		"Искать информацию":
			search_info_progress += AIM_PROGRESS_SEARCH
			add_hours(SEARCH_TIME)		
		"Готовиться к выезду":
			leave_country_progress += AIM_PROGRESS_SEARCH
			add_hours(SEARCH_TIME)
		"Работать":
			var probability = randf()
			if probability < WORK_PROBABILITY:
				var earned_money = int(round(randf_range(MONEY_EARN_MIN, MONEY_EARN_MAX) / 100)) * 100
				reaction_text = "[color=green]Удалось заработать " + str(earned_money) + " грн.[/color]" 
				money += earned_money
			else:
				fail = true
				reaction_text = "В этот раз не получилось ничего заработать. Но это не повод сдаваться." 
			add_hours(WORK_TIME)
		"Купить продукты":
			var probability = randf()
			if probability < FOOD_BUY_PROBABILITY:
				var spent_money = int(round(randf_range(FOOD_COST_MIN, FOOD_COST_MAX) / 100)) * 100
				money -= spent_money
				var coocked_food = randf_range(FOOD_INCREASE_MIN, FOOD_INCREASE_MAX)
				food += coocked_food
				reaction_text = "[color=green]Удалось приготовить несколько порций - " + str(coocked_food) + "[/color]"
			else:
				fail = true
				reaction_text = "Продукты испорчены. К сожалению, из них опасно готовить." 
			add_hours(BUY_FOOD_TIME)
		"Купить лекарства":
			var probability = randf()
			if probability < MEDICINES_BUY_PROBABILITY:
				var spent_money = int(round(randf_range(MEDICINES_COST_MIN, MEDICINES_COST_MAX) / 100)) * 100
				money -= spent_money
				var bought_medicines = MEDICINES_BUY_VALUE
				medicines += bought_medicines
				reaction_text = "[color=green]Удалось купить лекарства - " + str(bought_medicines) + "[/color]"
			else:
				fail = true
				reaction_text = "Все нужные лекарства разобрали, а те, что я нашёл, никуда не годятся."
			add_hours(BUY_MEDICINES_TIME)
		"Укрепить дом":
			var probability = randf()
			if probability < HOUSE_REPAIR_PROBABILITY:
				var spent_money = int(round(randf_range(HOUSE_REPAIR_COST_MIN, HOUSE_REPAIR_COST_MAX) / 100)) * 100
				money -= spent_money
				var repaired_house = HOUSE_REPAIR_VALUE
				house += repaired_house
				reaction_text = "Теперь наш дом укреплён - " + str(repaired_house) +  "[/color]"
			else:
				fail = true
				reaction_text = "Не получилось ничего починить, но я готова попробовать ещё раз."
			add_hours(HOUSE_REPAIR_TIME)
		"Лечить":
			medicines -= MEDICINES_FOR_HEALING
			for current_friend in friends:
				friend.is_sick = false
			add_hours(HEAL_TIME)
		"Поддержать всех":
			for current_friend in friends:
				current_friend.increase_mood(SUPPORT_MOOD_INCREASE)
			time_manager.current_time = END_DAY_TIME
	
	dialog_avatar.texture = load(friend.image_path)

	var random_index = randi_range(0, reactions[friend.id][selected_action].size() - 1)
	var random_reaction_text = reactions[friend.id][selected_action][random_index]
	
	if fail:
		random_reaction_text = reaction_text
	else:
		random_reaction_text += "\n" + reaction_text
	
	apply_event()
	check_friends_life()
	is_lose()
	type_text(dialog_label, random_reaction_text)
	update_ui()

	if time_manager.current_time >= END_DAY_TIME:
		check_end_of_day()

func check_friends_life():
	for friend in friends:
		if friend.mood <= MOOD_THRESHOLD_DEATH:
			friend.is_alive = false

	var all_dead = true
	for friend in friends:
		if friend.is_alive:
			all_dead = false
			break
	
	if all_dead:
		time_manager.is_lose = "lose.txt"
		return
			
	if house < HOUSE_THRESHOLD_DEATH:
		time_manager.is_lose = "house_lose.txt"
		for friend in friends:
			friend.is_alive = false
			
	if food < FOOD_THRESHOLD_DEATH:
		time_manager.is_lose = "food_lose.txt"
		for friend in friends:
			friend.is_alive = false
			
	if money < MONEY_THRESHOLD_DEATH:
		time_manager.is_lose = "money_lose.txt"
		for friend in friends:
			friend.is_alive = false
			
	update_ui()

func is_lose():
	if leave_country_progress >= 100:
		time_manager.is_lose = "win.txt"
		
		update_ui()
		
		await fade_in()
		
		night_label.text = "Мы успешно покинули страну!"
		night_label.text += "\nСпасибо тебе!"
		
		await get_tree().create_timer(NIGHT_EVENT_WAIT_TIME).timeout
		
		save_game_data()
		get_tree().change_scene_to_file("res://novel_scene.tscn")
		return
	
	var all_dead = true
	for friend in friends:
		if friend.is_alive:
			all_dead = false
			break
	
	# Если все друзья мертвы, устанавливаем is_lose
	if all_dead:
		check_end_of_day()

func apply_event():
	var current_time = time_manager.current_time

	for event in game_events:
		if event.event_type == "Воздушная тревога":
			if current_time >= event.start_time and current_time <= event.start_time + event.duration:
				alarm_icon.visible = true
				var sound_audio_stream = load("res://sounds/air_alarm.mp3") as AudioStream
				SoundManager.play_sound(sound_audio_stream)
				
				var alarm_probability = randf()
				if alarm_probability <= ALARM_PROBABILITY_VALUE:
					sound_audio_stream = load("res://sounds/missile_explosion.mp3") as AudioStream
					SoundManager.play_sound(sound_audio_stream)
					var house_damage = randi_range(HOUSE_DAMAGE_MIN, HOUSE_DAMAGE_MAX)
					house -= house_damage
			else:
				alarm_icon.visible = false

		elif event.event_type == "Отключение света":
			if current_time >= event.start_time and current_time <= event.start_time + event.duration:
				blackout_icon.visible = true
				for friend in friends:
					friend.actions = friend.actions_blackout
			else:
				blackout_icon.visible = false
				for friend in friends:
					friend.actions = friend.default_actions

func type_text(label: RichTextLabel, text: String, speed: float = DEFAULT_TYPE_SPEED) -> void:
	label.text = ""
	var current_text = ""
	for char in text:
		current_text += char
		label.text = current_text
		await get_tree().create_timer(speed).timeout

func add_hours(hours: int):
	time_manager.current_time += hours
		
func check_end_of_day():
	time_manager.reset_day()
	
	apply_daily_losses()
		
	await fade_in()
	
	for friend in friends:
		if friend.is_alive == false:
			night_text += "\nК сожалению, " + friend.name + " больше не с нами."
	
	night_label.text = "ОСТАЛОСЬ " + str(day_remains) + " ДНЕЙ"
	event_night_label.text = check_night_events()
	
	await get_tree().create_timer(NIGHT_EVENT_WAIT_TIME).timeout
	
	night_label.text = ""
	event_night_label.text = ""
	
	save_game_data()
	get_tree().change_scene_to_file("res://novel_scene.tscn")

func check_night_events():
	var game_night_events = game_events_manager.generate_night_events(time_manager.current_date)
	
	for friend in friends:
		if friend.is_sick == true:
			friend.is_alive = false

	# Фильтруем только живых друзей для выбора случайного друга
	var alive_friends = []
	for friend in friends:
		if friend.is_alive:
			alive_friends.append(friend)
	
	for event in game_night_events:		
		if event.event_type == "Болезнь":
			if alive_friends.size() != 0:
				var sick_friend = alive_friends[randi_range(0, alive_friends.size() - 1)]
				sick_friend.is_sick = true
				night_text += "\n" + sick_friend.name + " заболевает."

		if event.event_type == "Ночной обстрел":
			var sound_audio_stream = load("res://sounds/missile_explosion.mp3") as AudioStream
			SoundManager.play_sound(sound_audio_stream)
			var house_damage = randi_range(HOUSE_DAMAGE_MIN, HOUSE_DAMAGE_MAX)
			house -= house_damage
			night_text += "\nНочной ракетный обстрел. Прочность дома снижена на " + str(house_damage) + " единиц."
	
	if night_text == "":
		night_text = "Эта ночь прошла спокойно." 
	
	return night_text

func apply_daily_losses() -> void:
	day_remains -= 1
	food -= friends.size() * 2
	var lost_money = int(round(randf_range(DAILY_MONEY_LOSS_MIN, DAILY_MONEY_LOSS_MAX) / 100)) * 100
	money -= lost_money
	
	check_friends_life()
	
	for friend in friends:
		friend.decrease_mood(MOOD_DECREASE_PER_DAY_MAX)
		
	check_friends_life()
	
	var dead_count = 0
	for friend in friends:
		if not friend.is_alive:
			dead_count += 1
	
	for friend in friends:
		friend.decrease_mood(dead_count)
	
	update_ui()


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

func copy_game_data_to_user() -> void:
	var user_file_path = "user://game.json"
	var res_file_path = "res://game.json"
	
	# Проверяем, существует ли файл в user://
	if not FileAccess.file_exists(user_file_path):
		# Открываем файл из res:// для чтения
		var res_file = FileAccess.open(res_file_path, FileAccess.READ)
		var file_content = res_file.get_as_text()
		res_file.close()

		# Открываем или создаём файл в user:// для записи
		var user_file = FileAccess.open(user_file_path, FileAccess.WRITE)
		user_file.store_string(file_content)
		user_file.close()
	else:
		print("Файл уже существует в user://")

func load_game_data() -> void:
	var file = FileAccess.open("user://game.json", FileAccess.READ)
	var data = file.get_as_text()
	var json = JSON.new()  # Создаём экземпляр JSON
	json.parse(data)  # Парсим JSON

	var parsed_data = json.data  # Получаем данные через json.data

	# Загрузка player_stats
	money = parsed_data["player_stats"]["money"]
	food = parsed_data["player_stats"]["food"]
	house = parsed_data["player_stats"]["house"]
	medicines = parsed_data["player_stats"]["medicines"]
	search_info_progress = parsed_data["player_stats"]["search_info_progress"]
	hold_money_progress = parsed_data["player_stats"]["hold_money_progress"]
	leave_country_progress = parsed_data["player_stats"]["leave_country_progress"]
	day_remains = parsed_data["player_stats"]["day_remains"]

	# Загрузка персонажей
	inna = Character.new(
		"inna", 
		parsed_data["friends"]["inna"]["name"], 
		parsed_data["friends"]["inna"]["mood"], 
		"res://chars/inna.png",
		parsed_data["friends"]["inna"]["is_sick"],
		parsed_data["friends"]["inna"]["is_alive"], 
		parsed_data["friends"]["inna"]["actions"], 
		parsed_data["friends"]["inna"]["default_actions"]
	)
	inna.blocked_actions = parsed_data["friends"]["inna"]["blocked_actions"]
	inna.actions_blackout = parsed_data["friends"]["inna"]["actions_blackout"]
	inna.actions_sick = parsed_data["friends"]["inna"]["actions_sick"]

	max = Character.new(
		"max", 
		parsed_data["friends"]["max"]["name"], 
		parsed_data["friends"]["max"]["mood"], 
		"res://chars/max.png",
		parsed_data["friends"]["max"]["is_sick"],
		parsed_data["friends"]["max"]["is_alive"],
		parsed_data["friends"]["max"]["actions"], 
		parsed_data["friends"]["max"]["default_actions"]
	)
	max.blocked_actions = parsed_data["friends"]["max"]["blocked_actions"]
	max.actions_blackout = parsed_data["friends"]["max"]["actions_blackout"]
	max.actions_sick = parsed_data["friends"]["max"]["actions_sick"]

	kostya = Character.new(
		"kostya", 
		parsed_data["friends"]["kostya"]["name"], 
		parsed_data["friends"]["kostya"]["mood"], 
		"res://chars/kostya.png",
		parsed_data["friends"]["kostya"]["is_sick"],
		parsed_data["friends"]["kostya"]["is_alive"], 
		parsed_data["friends"]["kostya"]["actions"], 
		parsed_data["friends"]["kostya"]["default_actions"]
	)
	kostya.blocked_actions = parsed_data["friends"]["kostya"]["blocked_actions"]
	kostya.actions_blackout = parsed_data["friends"]["kostya"]["actions_blackout"]
	kostya.actions_sick = parsed_data["friends"]["kostya"]["actions_sick"]

	time_manager.current_date = DateTime.datetime({"year": parsed_data["player_stats"]["year"], "month": parsed_data["player_stats"]["month"], "day": parsed_data["player_stats"]["day"], "hour": 8, "minute": 0, "second": 0})

	# Создаём список персонажей
	friends = [inna, max, kostya]

	file.close()

func save_game_data() -> void:
	var data = {
		"player_stats": {
			"year": time_manager.current_date.year,
			"month": time_manager.current_date.month,
			"day": time_manager.current_date.day,
			"money": money,
			"food": food,
			"house": house,
			"medicines": medicines,
			"day_remains": day_remains,
			"search_info_progress": search_info_progress,
			"hold_money_progress": hold_money_progress,
			"leave_country_progress": leave_country_progress
		},
		"friends": {
			"inna": {
				"id": inna.id,
				"name": inna.name,
				"mood": inna.mood,
				"is_sick": inna.is_sick,
				"is_alive": inna.is_alive,
				"actions": inna.actions,
				"default_actions": inna.default_actions,
				"actions_blackout": inna.actions_blackout,
				"actions_sick": inna.actions_sick,
				"blocked_actions": inna.blocked_actions
			},
			"max": {
				"id": max.id,
				"name": max.name,
				"mood": max.mood,
				"is_sick": max.is_sick,
				"is_alive": max.is_alive,
				"actions": max.actions,
				"default_actions": max.default_actions,
				"actions_blackout": max.actions_blackout,
				"actions_sick": max.actions_sick,
				"blocked_actions": max.blocked_actions
			},
			"kostya": {
				"id": kostya.id,
				"name": kostya.name,
				"mood": kostya.mood,
				"is_sick": kostya.is_sick,
				"is_alive": kostya.is_alive,
				"actions": kostya.actions,
				"default_actions": kostya.default_actions,
				"actions_blackout": kostya.actions_blackout,
				"actions_sick": kostya.actions_sick,
				"blocked_actions": kostya.blocked_actions
			}
		}
	}

	# Открываем файл на запись с флагом для перезаписи без подтверждения
	var file = FileAccess.open("user://game.json", FileAccess.WRITE_READ)
	
	# Преобразуем данные в строку JSON
	var json_string = JSON.stringify(data)
	
	# Сохраняем JSON в файл
	file.store_string(json_string)
	file.close()


func delete_game_data() -> void:
	var dir = DirAccess.open("user://")
	dir.remove("game.json")
