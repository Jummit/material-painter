extends Resource

"""
A single layer of a `LayerMaterial`

The `properties` `Dictionary` holds a `mask` that is used when blending the layers
and can hold a `LayerTexture` for each map (for example albedo, height, etc...).
"""

# warning-ignore-all:unused_class_variable
export var properties : Dictionary
export var name := "Untitled Layer"
export var opacity := 1.0
export var blend_mode := "normal"
export var visible := true

const TextureLayer = preload("res://layers/texture_layer.gd")

func _init() -> void:
	resource_local_to_scene = true


func get_maps() -> Dictionary:
	var maps := {}
	for map_type in Globals.TEXTURE_MAP_TYPES:
		if map_type in properties:
			maps[map_type] = properties[map_type]
	return maps


func get_depending_layer_textures(texture_layer : TextureLayer) -> Array:
	var layer_textures := []
	for map_type in Globals.TEXTURE_MAP_TYPES:
		if map_type in properties:
			for to_check_texture_layer in properties[map_type].layers:
				if texture_layer == to_check_texture_layer:
					layer_textures.append(properties[map_type])
					continue
	return layer_textures
