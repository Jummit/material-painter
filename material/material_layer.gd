extends Reference

"""
A layer of a `LayerMaterial`

`mask` is used when blending the layers.
`maps` is a dictionary which can hold a `LayerTexture` for each map, for example
albedo, metallic or height.

`MaterialLayer`s can be hidden, which excludes them from the result of the
`LayerMaterial`.

It is marked dirty when the child `LayerTexture`s change, which will mark the
parent `LayerMaterial` dirty.
"""

var name : String
var visible := true
var is_folder := false
var folder_results : Dictionary
var layers : Array
var enabled_maps : Dictionary
var opacities : Dictionary
var blend_modes : Dictionary
# warning-ignore:unused_class_variable
var mask : LayerTexture
var main : LayerTexture

var settings : Dictionary

var parent : Reference
var dirty := true

const TextureLayer = preload("texture_layer/texture_layer.gd")
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const LayerTexture = preload("res://material/layer_texture.gd")

func _init(data := {}) -> void:
	name = data.get("name", "")
	visible = data.get("visible", true)
	opacities = data.get("opacities", {})
	enabled_maps = data.get("enabled_maps", {})
	blend_modes = data.get("blend_modes", {})
	is_folder = data.get("folder", false)
	main = LayerTexture.new(data.get("main", {}))
	main.parent = self
	if "mask" in data:
		mask = LayerTexture.new(data.get("mask"))
		mask.parent = self
	name = "Untitled Folder" if is_folder else "Untitled Layer"
	for layer in data.get("layers", []):
		add_layer(get_script().new(layer))


func serialize() -> Dictionary:
	var data := {
		main = main.serialize(),
		name = name,
		enabled_maps = enabled_maps,
		opacities = opacities,
		blend_modes = blend_modes,
		visible = visible,
		is_folder = is_folder,
	}
	if mask:
		data.mask = mask.serialize()
	for layer in layers:
		data.layers.append(layer.serialize())
	return data


func get_properties() -> Array:
	var properties := []
	return properties


func add_layer(layer) -> void:
	layers.append(layer)
	layer.parent = self


func get_opacity(map : String) -> float:
	return opacities.get(map, 1.0)


func get_blend_mode(map : String) -> float:
	return blend_modes.get(map, "normal")


func update(context : MaterialGenerationContext) -> void:
	if not dirty:
		return
	if mask:
		var result = mask.update(context)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
	var result = main.update(context)
	while result is GDScriptFunctionState:
		yield(result, "completed")
	if is_folder:
		for layer in layers:
			result = layer.update(context)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
		
		for map in enabled_maps:
			var blending_layers := []
			for layer in layers:
				var blending_layer = layer.get_blending_layer(context)
				if blending_layer is GDScriptFunctionState:
					blending_layer = yield(blending_layer, "completed")
				blending_layers.append(blending_layer)
			
			if blending_layers.empty():
				folder_results.erase(map)
				continue
			
			result = yield(context.blending_viewport_manager.blend(
					blending_layers, context.result_size,
					get_instance_id() + map.hash()), "completed")
			
			folder_results[map] = result
	dirty = false


func get_layer_material_in() -> Reference:
# warning-ignore:unsafe_property_access
	if "is_folder" in parent and parent.is_folder:
# warning-ignore:unsafe_method_access
		return parent.get_layer_material_in()
	else:
		return parent


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
# warning-ignore:unsafe_method_access
	get_layer_material_in().mark_dirty(shader_dirty)


func duplicate() -> Object:
	return get_script().new(serialize())
