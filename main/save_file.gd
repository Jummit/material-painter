extends Resource

"""
The `Resource` that stores all the data of a Material Painter file
"""

# warning-ignore:unused_class_variable
export var layer_material : Resource = LayerMaterial.new()

const LayerMaterial = preload("res://material_layers/layer_material.gd")
