extends Reference

var layers : Array

var results : Dictionary
var parent : Reference
var dirty := true
var dirty_icons : Array
var icons : Dictionary

const TextureLayer = preload("texture_layer.gd")
const TextureLayerLoader = preload("texture_layer_loader.gd")
const MaterialGenerationContext = preload("material_generation_context.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}) -> void:
	for layer in data.get("layers", []):
		add_layer(TextureLayerLoader.load_layer(layer))


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
	if not dirty and not icon and map in results:
		return results[map]
	var blending_layers := []
	for layer in layers:
		if not layer.visible:
			continue
		var blending_layer = layer.get_blending_layer(context, map)
		while blending_layer is GDScriptFunctionState:
			blending_layer = yield(blending_layer, "completed")
		if blending_layer:
			blending_layers.append(blending_layer)
	if blending_layers.empty():
		results.erase(map)
		return null
	results[map] = yield(context.blending_viewport_manager.blend(
			blending_layers, context.icon_size if icon else context.result_size,
			-1 if icon else get_instance_id() + map.hash()), "completed")
	dirty = false
	return results[map]


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
	return get_script().new(serialize().duplicate(true))
