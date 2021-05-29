extends Node

const Properties = preload("res://addons/property_panel/properties.gd")

var config := ConfigFile.new() setget set_config

# warning-ignore:unused_class_variable
var settings = [
	Properties.EnumProperty.new("generate_utility_maps", ["On Use", "On Startup"]),
	Properties.BoolProperty.new("enable_antialiasing"),
]

func _ready() -> void:
	config.load("user://settings.cfg")


func get_setting(setting : String):
	var default
	for property in settings:
		if property.name == setting:
			default = property.default
	return config.get_value("main", setting, default)


func set_config(to) -> void:
	config = to
	config.save("user://settings.cfg")
