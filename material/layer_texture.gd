extends Reference

var layers : Array

var results : Dictionary
var parent : Reference
var dirty := true
var dirty_icons : Array
var icons : Dictionary

const TextureLayer = preload("texture_layer/texture_layer.gd")
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}) -> void:
	for layer in data.get("layers", []):
		add_layer(get_script().new(layer))


func serialize() -> Dictionary:
	var data := {
		layers = [],
	}
	for layer in layers:
		data.layers.append(layer.serialize())
	return data


func add_layer(layer) -> void:
	layers.append(layer)
	layer.parent = self


func get_result(context : MaterialGenerationContext, map : String,
		icon := false) -> Texture:
	var blending_layers := []
	for layer in layers:
		var blending_layer = layer.get_blending_layer(context, map)
		if blending_layer is GDScriptFunctionState:
			blending_layer = yield(blending_layer, "completed")
		if blending_layer:
			blending_layers.append(blending_layer)
	if blending_layers.empty():
		return null
	return yield(context.blending_viewport_manager.blend(
			blending_layers, context.icon_size if icon else context.result_size,
			-1 if icon else get_instance_id() + map.hash()), "completed")


func update(context : MaterialGenerationContext,
		maps := Constants.TEXTURE_MAP_TYPES) -> void:
	if not dirty:
		return
	for map in maps:
		var result = get_result(context, map)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		results[map] = result
	dirty = false


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
	for icon in icons:
		dirty_icons.append(icon)
# warning-ignore:unsafe_method_access
	parent.mark_dirty(shader_dirty)


func get_icon(map : String, context : MaterialGenerationContext) -> Texture:
	if not map in icons or map in dirty_icons:
		var result = get_result(context, map, true)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		icons[map] = result
		dirty_icons.erase(map)
	return icons[map]


func duplicate() -> Object:
	return get_script().new(serialize())
