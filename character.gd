class_name Character

var id: String
var name: String
var mood: int
var image_path: String
var is_sick: bool
var is_alive: bool
var actions: Array
var default_actions: Array
var blocked_actions: Array
var actions_blackout: Array
var actions_sick: Array

func _init(id: String, name: String, mood: int, image_path: String, is_sick: bool, is_alive: bool, actions: Array, default_actions: Array) -> void:
	self.id = id
	self.name = name
	self.mood = mood
	self.image_path = image_path
	self.is_alive = is_alive
	self.is_sick = is_sick
	self.actions = actions
	self.default_actions = default_actions
	self.blocked_actions = []
	self.actions_blackout = []
	self.actions_sick = []

func increase_mood(mood_value):
	mood += mood_value
	mood = clamp(mood, 0, 10)

func decrease_mood(mood_value):
	mood -= mood_value
	mood = clamp(mood, 0, 10)
