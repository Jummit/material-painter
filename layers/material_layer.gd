extends Resource

"""
A single layer of a `LayerMaterial`

The `properties` `Dictionary` holds a `mask` that is used when blending the layers
and can hold a `LayerTexture` for each map (for example albedo, height, etc...).
"""

# warning-ignore-all:unused_class_variable
export var maps : Dictionary
export var mask : Resource
export var name := "Untitled Layer"
export var opacity := 1.0
export var blend_mode := "normal"
export var visible := true

const TextureLayer = preload("res://layers/texture_layer.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")

func _init() -> void:
	resource_local_to_scene = true


func get_depending_layer_textures(texture_layer : TextureLayer) -> Array:
	var layer_textures := []
	for map in maps.values():
		map = map as LayerTexture
		if texture_layer in map.get_flat_layers():
			layer_textures.append(map)
			continue
	return layer_textures
