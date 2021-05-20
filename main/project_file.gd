extends Resource

"""
A Material Painter file
"""

const BitmapTextureLayer = preload("res://data/texture/layers/bitmap_texture_layer.gd")
const FileTextureLayer = preload("res://data/texture/layers/file_texture_layer.gd")

# warning-ignore-all:unused_class_variable
export var layer_materials : Array 
export var model_path : String
export var result_size := Vector2(1024, 1024)

func _init() -> void:
	resource_local_to_scene = true


func save_bitmap_layers() -> void:
	for material in layer_materials:
		for layer in material.get_texture_layers():
			if layer is BitmapTextureLayer:
				layer.save()
