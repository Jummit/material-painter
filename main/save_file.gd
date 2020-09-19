extends Resource

"""
A Material Painter file
"""

# warning-ignore-all:unused_class_variable
export var layer_material : Resource = LayerMaterial.new()
export var model_path : String

const LayerMaterial = preload("res://layers/layer_material.gd")

func _init() -> void:
	resource_local_to_scene = true
