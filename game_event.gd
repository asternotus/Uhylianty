# game_event.gd
class_name GameEvent

var event_type: String
var duration: int
var start_time: int

func _init(event_type: String, duration: int, start_time: int):
	self.event_type = event_type
	self.duration = duration
	self.start_time = start_time

func event_to_string() -> String:
	return "%s на %d часов с %02d:00" % [event_type, duration, start_time]
