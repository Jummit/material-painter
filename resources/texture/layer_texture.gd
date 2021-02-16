extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a `result` which is updated when settings of the layers change.

`MaterialLayer`s can be hidden, which excludes them from the result of the
`LayerMaterial`.

It will mark the parent `LayerTexture` dirty when marked dirty.

If `shader_dirty` is true, the shader needs to be recompiled. This is not
necessary if only parameters changed.
"""

export var layers : Array setget set_layers
# warning-ignore:unused_class_variable
export var opacity := 1.0
# warning-ignore:unused_class_variable
export var blend_mode := "normal"
# warning-ignore:unused_class_variable

var parent
var result : Texture
var icon : Texture
var dirty := true
var icon_dirty := true
var shader_dirty := false

const TextureFolder = preload("res://resources/texture/texture_folder.gd")

func _init() -> void:
	resource_local_to_scene = true


func set_layers(to):
	layers = to
	for layer in layers:
		layer.parent = self


func update(force_all := false) -> void:
	if not dirty and not force_all:
		return
	for layer in layers:
		var update_result = layer.update(force_all)
		if update_result is GDScriptFunctionState:
			yield(update_result, "completed")
	result = yield(generate_result(parent.get_layer_material_in().result_size,
			shader_dirty or force_all, get_instance_id()), "completed")
	shader_dirty = false
	dirty = false


func generate_result(result_size : Vector2, update_shader := false,
		id := -1) -> Texture:
	var blending_layers := []
	for layer in layers:
		if not layer.visible:
			continue
		var shader_layer = layer._get_as_shader_layer()
		if shader_layer is GDScriptFunctionState:
			shader_layer = yield(shader_layer, "completed")
		blending_layers.append(shader_layer)
	return yield(LayerBlendViewportManager.blend(blending_layers, result_size,
			id, update_shader), "completed")


func update_icon() -> void:
	if icon_dirty:
		icon = yield(generate_result(Vector2(32, 32)), "completed")
		icon_dirty = false


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


func mark_dirty(shader_too := false) -> void:
	dirty = true
	icon_dirty = true
	if shader_too:
		shader_dirty = true
	parent.mark_dirty(shader_too)


func get_layer_material_in() -> Resource:
	return parent.get_layer_material_in()
