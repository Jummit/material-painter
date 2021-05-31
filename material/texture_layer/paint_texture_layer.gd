extends "texture_layer.gd"

# warning-ignore:unused_class_variable
var paint_textures : Dictionary

func _init(data := {}).(data) -> void:
	pass


func serialize() -> Dictionary:
	var data := .serialize()
	return data


func get_type() -> String:
	return "paint"
