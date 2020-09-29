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


func get_depending_layer_texture(texture_layer : TextureLayer) -> LayerTexture:
	for layer in maps.values():
		if texture_layer in layer.get_flat_layers():
			return layer
	return null


func update_all_layer_textures(result_size : Vector2) -> void:
	for layer_texture in maps.values() + [mask]:
		if layer_texture:
			layer_texture.update_result(result_size)


func get_layer_texture_of_texture_layer(texture_layer):
	for layer_texture in maps.values() + [mask]:
		if layer_texture:
			if texture_layer in layer_texture.get_flat_layers():
				return layer_texture
