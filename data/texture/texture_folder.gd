extends "blending_texture_layer.gd"

var layers : Array

var result : Texture

func _init(data := {}).(data) -> void:
	for layer in data.layers:
		layers.append(get_script().new(layer))


func serialize() -> Dictionary:
	var data := .serialize()
	for layer in layers:
		data.layers.append(layer.serialize())
	return data


func update(context : MaterialGenerationContext, force_all := false) -> void:
	if not dirty and not force_all:
		return
	var blending_layers := []
	for layer in layers:
		if not layer.visible:
			continue
		var shader_layer = layer._get_as_shader_layer()
		if shader_layer is GDScriptFunctionState:
			shader_layer = yield(shader_layer, "completed")
		blending_layers.append(shader_layer)
	result = yield(context.blending_viewport_manager.blend(blending_layers,
			context.result_size, get_instance_id(),
			shader_dirty), "completed")
	dirty = false


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	var layer := BlendingLayer.new("texture({texture}, uv)", blend_mode, opacity)
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	layer.uniform_values.append(result)
	return layer
