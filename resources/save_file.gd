extends Resource

"""
A Material Painter file
"""

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")

# warning-ignore-all:unused_class_variable
export var layer_materials : Array 
export var model_path : String

func _init() -> void:
	resource_local_to_scene = true


func pre_save() -> void:
	for layer_material in layer_materials:
		for material_layer in layer_material.get_flat_layers():
			for layer_texture in material_layer.get_layer_textures():
				for texture_layer in layer_texture.get_flat_layers():
					if texture_layer is BitmapTextureLayer:
						texture_layer.save()
