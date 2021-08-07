extends Reference

"""
A Material Painter file
"""

# warning-ignore-all:unused_class_variable
var layer_materials : Array 
var path : String
var model_path : String
var result_size := Vector2(1024, 1024)

const MaterialLayerStack = preload("res://material/material_layer_stack.gd")

func _init(data := {}) -> void:
	model_path = data.get("model_path", "")
	result_size = str2var(data.get("result_size", "Vector2(1024, 1024)"))
	for layer_data in data.get("layer_materials", []):
		layer_materials.append(MaterialLayerStack.new(layer_data))


func serialize() -> Dictionary:
	var data := {
		layer_materials = [],
		model_path = model_path,
		result_size = var2str(result_size),
	}
	for layer in layer_materials:
		data.layer_materials.append(layer.serialize())
	return data


func get_config() -> String:
	return "user://projects/".plus_file(path.get_file().get_basename()) + ".cfg"
