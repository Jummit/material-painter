extends Resource

"""
The `Resource` that stores all the data of a Material Painter file
"""

# warning-ignore:unused_class_variable
export var layer_material : Resource = LayerMaterial.new()

const LayerMaterial = preload("res://layers/layer_material.gd")

func _init() -> void:
	resource_local_to_scene = true
