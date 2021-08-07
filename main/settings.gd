extends Node

signal changed

const Properties = preload("res://addons/property_panel/properties.gd")

var config := ConfigFile.new() setget set_config

var settings := [
	Properties.EnumProperty.new("generate_utility_maps", ["On Use", "On Startup"]),
	Properties.BoolProperty.new("enable_vsync", true),
]

func _ready() -> void:
	config.load("user://settings.cfg")
	emit_signal("changed")


func get_setting(setting : String):
	var default
	for property in settings:
		if property.name == setting:
			default = property.default
	return config.get_value("main", setting, default)


func set_config(to) -> void:
	config = to
	config.save("user://settings.cfg")
	emit_signal("changed")
