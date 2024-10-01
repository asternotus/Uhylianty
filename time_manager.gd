# TimeManager.gd — класс без узла
extends Node

class_name TimeManager

var current_time: int = 8  # Текущее время в часах
var hours_per_day: int = 16  # Количество доступных часов в день
var current_date: DateTime  # Объект для отслеживания даты
var is_lose = ""

func _init():	
	pass

func spend_time(hours: int):
	hours_per_day -= hours

# Функция для получения текущей даты и времени в нужном формате
func get_current_date_time() -> String:
	var months = ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"]
	var month_name = months[current_date.month - 1]  # Получаем название месяца
	return "%d %s, %d, %02d:00" % [current_date.day, month_name, current_date.year, current_time]  # Формат: День Месяц, Год, Время
	
func get_default_format_date() -> String:
	return "%02d.%02d.%d" % [current_date.day, current_date.month, current_date.year]

func reset_day():
	current_date = current_date.add_days(1)  # Переход на следующий день
	current_time = 8  # Сбрасываем время на 8 утра
	print(get_current_date_time())  # Выводим новую дату
