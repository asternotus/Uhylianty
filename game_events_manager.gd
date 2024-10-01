# event_manager.gd
var events: Array = []
var night_events: Array = []

# Основной метод для генерации событий в зависимости от даты
func generate_events(current_date: DateTime):
	events.clear()
	var day = current_date.day
	var month = current_date.month
	
	match month:
		# Июнь
		6:
			if day <= 2:
				add_event(0.05, "Воздушная тревога", 2, 4)
			elif day <= 10:
				add_event(0.05, "Воздушная тревога", 2, 4)
			elif day <= 20:
				add_event(0.1, "Воздушная тревога", 2, 4)
			elif day <= 25:
				add_event(0.1, "Воздушная тревога", 2, 4)
				add_event(0.1, "Отключение света", 2, 4)
			elif day <= 31:
				add_event(0.3, "Воздушная тревога", 2, 4)
				add_event(0.1, "Отключение света", 2, 4)
		
		# Июль
		7:
			if day <= 10:
				add_event(0.3, "Воздушная тревога", 2, 4)
				add_event(0.1, "Отключение света", 2, 4)
			elif day <= 20:
				add_event(0.3, "Воздушная тревога", 2, 4)
				add_event(0.5, "Отключение света", 2, 4)
			elif day <= 31:
				add_event(0.5, "Воздушная тревога", 2, 4)
				add_event(0.3, "Отключение света", 2, 4)

		# Август
		8:
			if day <= 10:
				add_event(0.5, "Воздушная тревога", 2, 4)
				add_event(0.5, "Отключение света", 2, 4)
			elif day <= 20:
				add_event(0.5, "Воздушная тревога", 2, 4)
				add_event(0.5, "Отключение света", 2, 4)

	return events

# Основной метод для генерации событий в зависимости от даты
func generate_night_events(current_date: DateTime):
	night_events.clear()
	var day = current_date.day
	var month = current_date.month
	
	match month:
		
		# Июнь
		6:
			if day <= 2:
				pass
			elif day <= 10:
				add_night_event(0.05, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 20:
				add_night_event(0.1, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 25:
				add_night_event(0.1, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 31:
				add_night_event(0.3, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
		
		# Июль
		7:
			if day <= 10:
				add_night_event(0.3, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 20:
				add_night_event(0.3, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 31:
				add_night_event(0.5, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)

		# Август
		8:
			if day <= 10:
				add_night_event(0.5, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)
			elif day <= 20:
				add_night_event(0.5, "Ночной обстрел", 0, 0)
				add_night_event(0.2, "Болезнь", 0, 0)

	return night_events

func add_event(chance: float, event_type: String, min_duration: int, max_duration: int, count: int = 1) -> void:
	for i in range(count):
		if randf() < chance:
			var duration = randi_range(min_duration, max_duration)
			var start_time = randi_range(10, 22 - duration)
			events.append(GameEvent.new(event_type, duration, start_time))

func add_night_event(chance: float, event_type: String, min_duration: int, max_duration: int, count: int = 1) -> void:
	for i in range(count):
		if randf() < chance:
			var duration = randi_range(min_duration, max_duration)
			var start_time = randi_range(10, 22 - duration)
			night_events.append(GameEvent.new(event_type, duration, start_time))
