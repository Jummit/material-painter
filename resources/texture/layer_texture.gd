extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a `result` which is updated when settings of the layers change.
"""

export var layers : Array
# warning-ignore:unused_class_variable

var parent
var result : Texture
var icon : Texture

const TextureFolder = preload("res://resources/texture/texture_folder.gd")

func _init() -> void:
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer in layers:
		layer.parent = self


func update(keep_viewport := true, update_shader := false) -> void:
	result = yield(generate_result(Globals.result_size, keep_viewport, update_shader), "completed")
	icon = yield(generate_result(Vector2(32, 32), false), "completed")
	for layer in layers:
		yield(layer.update_icons(), "completed")


func generate_result(result_size : Vector2, update_shader := false, keep_viewport := true, custom_id := 0) -> Texture:
	var blending_layers := []
	for layer in get_flat_layers(layers, false):
		var shader_layer = layer._get_as_shader_layer()
		if shader_layer is GDScriptFunctionState:
			shader_layer = yield(shader_layer, "completed")
		blending_layers.append(shader_layer)
	return yield(LayerBlendViewportManager.blend(blending_layers, result_size, get_instance_id() + custom_id if keep_viewport else -1, update_shader), "completed")


func get_flat_layers(layer_array : Array = layers, add_hidden := true, add_folders := false) -> Array:
	var flat_layers := []
	for layer in layer_array:
		if (not add_hidden) and not layer.visible:
			continue
		if layer is TextureFolder:
			flat_layers += get_flat_layers(layer.layers, add_hidden)
		if (not layer is TextureFolder) or add_folders:
			flat_layers.append(layer)
	return flat_layers
