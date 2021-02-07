extends Resource

"""
A Material Painter file
"""

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")

# warning-ignore-all:unused_class_variable
export var layer_materials : Array 
export var model_path : String

func _init() -> void:
	resource_local_to_scene = true


func save_bitmap_layers() -> void:
	for texture_layer in find_texture_layers(BitmapTextureLayer):
		texture_layer.save()


func replace_paths(path : String, with : String) -> void:
	for texture_layer in find_texture_layers(FileTextureLayer):
		texture_layer.path = texture_layer.path.replace(path, with)


func find_texture_layers(type) -> Array:
	var layers := []
	for layer_material in layer_materials:
		for material_layer in layer_material.get_flat_layers():
			for layer_texture in material_layer.get_layer_textures():
				for texture_layer in layer_texture.get_flat_layers():
					if texture_layer is type:
						layers.append(texture_layer)
	return layers


func get_global_path(path : String) -> String:
	if path.begins_with("local"):
		return resource_path.get_base_dir().plus_file(path.trim_prefix("local"))
	else:
		return path


func get_local_asset_dir() -> String:
	return resource_path.get_base_dir().plus_file("assets")
