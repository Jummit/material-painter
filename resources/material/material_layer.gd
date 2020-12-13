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

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")

func _init() -> void:
	resource_local_to_scene = true


func update_all_layer_textures(result_size : Vector2) -> void:
	for layer_texture in maps.values() + [mask]:
		if layer_texture:
			yield(layer_texture.update_result(result_size), "completed")


func get_layer_texture_of_texture_layer(texture_layer):
	for layer_texture in maps.values() + [mask]:
		if layer_texture:
			if texture_layer in layer_texture.get_flat_layers(layer_texture.layers, true, true):
				return layer_texture


func get_layer_textures() -> Array:
	var layer_textures := maps.values()
	if mask:
		layer_textures.append(mask)
	return layer_textures
