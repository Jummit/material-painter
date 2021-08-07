extends Node

"""
Per-project settings

Every project gets its own config file under user://projects.
"""

signal changed

var config := ConfigFile.new()

func load_config(path : String) -> void:
	config.load(path)
	emit_signal("changed")


func save(path : String) -> void:
	config.save(path)


func get_setting(setting : String):
	return config.get_value("main", setting)


func set_setting(setting : String, to) -> void:
	config.set_value("main", setting, to)
