extends Reference

"""
A layer of a `MaterialLayerStack`

`mask` is used when blending the layers.
`maps` is a dictionary which can hold a `TextureLayerStack` for each map, for example
albedo, metallic or height.

`MaterialLayer`s can be hidden, which excludes them from the result of the
`MaterialLayerStack`.

It is marked dirty when the child `TextureLayerStack`s change, which will mark the
parent `MaterialLayerStack` dirty.
"""

var name : String
var visible := true
var folder_results : Dictionary
var layers : Array
var opacities : Dictionary
var is_folder := false
var blend_modes : Dictionary
var mask : TextureLayerStack
var main : TextureLayerStack
# warning-ignore:unused_class_variable
var hide_first_layer : bool

var parent : Reference
var dirty := true

const TextureLayer = preload("texture_layer.gd")
const TextureLayerLoader = preload("texture_layer_loader.gd")
const MaterialGenerationContext = preload("material_generation_context.gd")
const TextureLayerStack = preload("texture_layer_stack.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const Constants = preload("res://main/constants.gd")

func _init(data := {}) -> void:
	name = data.get("name", "Untitled Folder" if is_folder else "Untitled Layer")
	visible = data.get("visible", true)
	opacities = data.get("opacities", {})
	blend_modes = data.get("blend_modes", {})
	is_folder = data.get("is_folder", false)
	hide_first_layer = data.get("has_base", false)
	main = TextureLayerStack.new(data.get("main", {}))
	main.parent = self
	if "mask" in data:
		mask = TextureLayerStack.new(data.mask)
		mask.parent = self
	for layer in data.get("layers", []):
		add_layer(get_script().new(layer))


func serialize() -> Dictionary:
	var data := {
		name = name,
		visible = visible,
		is_folder = is_folder,
		has_base = hide_first_layer,
	}
	if mask:
		data.mask = mask.serialize()
	if is_folder:
		data.layers = []
		for layer in layers:
			data.layers.append(layer.serialize())
	else:
		data.main = main.serialize()
		data.opacities = opacities
		data.blend_modes = blend_modes
	return data


func get_result(map : String, context : MaterialGenerationContext) -> Texture:
	if is_folder:
		if not dirty and map in folder_results:
			return folder_results[map]
		for map in Constants.TEXTURE_MAP_TYPES:
			var blending_layers := []
			for layer in layers:
				if not layer.visible:
					continue
				var map_result = layer.get_result(map, context)
				while map_result is GDScriptFunctionState:
					map_result = yield(map_result, "completed")
				if not map_result:
					continue
				var blending_layer : BlendingLayer
				var layer_mask
				if layer.mask:
					layer_mask = layer.mask.get_result(context, "albedo")
					while layer_mask is GDScriptFunctionState:
						layer_mask = yield(layer_mask, "completed")
				blending_layer = BlendingLayer.new(
					"texture({result}, uv)",
					layer.get_blend_mode(map), layer.get_opacity(map), layer_mask)
				blending_layer.uniforms.result = map_result
				blending_layers.append(blending_layer)
			
			if blending_layers.empty():
				folder_results.erase(map)
				continue
			
			var result = context.blending_viewport_manager.blend(
					blending_layers, context.result_size,
					get_instance_id() + map.hash())
			while result is GDScriptFunctionState:
				result = yield(result, "completed")
			
			folder_results[map] = result
		dirty = false
		return folder_results.get(map)
	else:
		var result = main.get_result(context, map)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		return result


func add_layer(layer) -> void:
	layers.append(layer)
	layer.parent = self


func get_opacity(map : String) -> float:
	return opacities.get(map, 1.0)


func get_blend_mode(map : String) -> float:
	return blend_modes.get(map, "normal")


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
