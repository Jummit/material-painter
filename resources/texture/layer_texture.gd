extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a `result` which is updated when settings of the layers change.
"""

export var layers : Array
# warning-ignore:unused_class_variable

var result : Texture

const FolderLayer = preload("res://resources/folder_layer.gd")

func _init() -> void:
	resource_local_to_scene = true


func update_result(result_size : Vector2, keep_viewport := true, use_cached_shader := false) -> void:
	result = yield(generate_result(result_size, keep_viewport, use_cached_shader), "completed")


func generate_result(result_size : Vector2, keep_viewport := true, use_cached_shader := false, custom_id := 0) -> Texture:
	var blending_layers := []
	for layer in get_flat_layers(layers, false):
		var shader_layer = layer._get_as_shader_layer()
		if shader_layer is GDScriptFunctionState:
			shader_layer = yield(shader_layer, "completed")
		blending_layers.append(shader_layer)
	return yield(LayerBlendViewportManager.blend(blending_layers, result_size, get_instance_id() + custom_id if keep_viewport else -1, use_cached_shader), "completed")


func get_flat_layers(layer_array : Array = layers, add_hidden := true) -> Array:
	var flat_layers := []
	for layer in layer_array:
		if (not add_hidden) and not layer.visible:
			continue
		if layer is FolderLayer:
			flat_layers += get_flat_layers(layer.layers, add_hidden)
		else:
			flat_layers.append(layer)
	return flat_layers


func get_folders(layer_array : Array = layers) -> Array:
	var folders := []
	for layer in layer_array:
		if layer is FolderLayer:
			folders.append(layer)
			folders += get_folders(layer.layers)
	return folders
