extends Reference

"""
A Material Painter file
"""

# warning-ignore-all:unused_class_variable
var layer_materials : Array 
var model_path : String
var result_size := Vector2(1024, 1024)

const LayerMaterial = preload("res://data/material/layer_material.gd")

func _init(data := {}) -> void:
	model_path = data.get("model_path", "")
	result_size = data.get("result_size", Vector2(1024, 1024))
	for layer_data in data.get("layer_materials", []):
		var layer := LayerMaterial.new(layer_data)
		layer.parent = self
		layer_materials.append(layer)


func serialize() -> Dictionary:
	var data := {
		layer_materials = [],
		model_path = model_path,
		result_size = result_size,
	}
	for layer in layer_materials:
		data.layer_materials.append(layer.serialize())
	return data
