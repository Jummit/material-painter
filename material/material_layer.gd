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
var results : Dictionary
var layers : Array
var enabled_maps : Dictionary
var opacities : Dictionary
var is_folder := false
var blend_modes : Dictionary
# warning-ignore:unused_class_variable
var mask : TextureLayerStack
var main : TextureLayerStack
var base_texture_layer : TextureLayer

# warning-ignore:unused_class_variable
var settings : Dictionary

var parent : Reference
var dirty := true

const TextureLayer = preload("texture_layer.gd")
const TextureLayerLoader = preload("texture_layer_loader.gd")
const MaterialGenerationContext = preload("material_generation_context.gd")
const TextureLayerStack = preload("texture_layer_stack.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}) -> void:
	name = data.get("name", "Untitled Layer")
	visible = data.get("visible", true)
	opacities = data.get("opacities", {})
	enabled_maps = data.get("enabled_maps", {})
	blend_modes = data.get("blend_modes", {})
	is_folder = data.get("folder", false)
	main = TextureLayerStack.new(data.get("main", {}))
	main.parent = self
	if "mask" in data:
		mask = TextureLayerStack.new(data.mask)
		mask.parent = self
	if "base" in data:
		base_texture_layer = TextureLayerLoader.load_layer(data.base)
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
	if base_texture_layer:
		data.base = base_texture_layer.serialize()
	for layer in layers:
		data.layers.append(layer.serialize())
	return data


func get_result(map : String, context : MaterialGenerationContext) -> Texture:
	if not dirty and map in results:
		return results[map]
	for map in Constants.TEXTURE_MAP_TYPES:
		var blending_layers := []
		if base_texture_layer:
			var blending_layer = base_texture_layer.get_blending_layer(context,
					map)
			while blending_layer is GDScriptFunctionState:
				blending_layer = yield(blending_layer, "completed")
			if blending_layer:
				blending_layers.append(blending_layer)
		var self_result = main.get_result(context, map)
		while self_result is GDScriptFunctionState:
			self_result = yield(self_result, "completed")
		if self_result:
			var self_blending_layer := BlendingLayer.new(
				"texture({result}, uv)")
			self_blending_layer.uniforms.result = self_result
			blending_layers.append(self_blending_layer)
		
		for layer in layers:
			if not layer.visible:
				continue
			var map_result = get_result(map, context)
			while map_result is GDScriptFunctionState:
				map_result = yield(map_result, "completed")
			if not map_result:
				continue
			var blending_layer : BlendingLayer
			var layer_mask
			if mask:
				layer_mask = mask.get_result(context, "albedo")
				while layer_mask is GDScriptFunctionState:
					layer_mask = yield(layer_mask, "completed")
			blending_layer = BlendingLayer.new(
				"texture({result}, uv)",
				get_blend_mode(map), get_opacity(map), layer_mask)
			blending_layer.uniforms.result = map_result
			blending_layers.append(blending_layer)
		
		if blending_layers.empty():
			results.erase(map)
			continue
		
		var result = context.blending_viewport_manager.blend(
				blending_layers, context.result_size,
				get_instance_id() + map.hash())
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		
		results[map] = result
	dirty = false
	return results.get(map)


func get_properties() -> Array:
	var properties := []
	return properties


func add_layer(layer) -> void:
	layers.append(layer)
	layer.parent = self


func get_opacity(map : String) -> float:
	return opacities.get(map, 1.0)


func get_blend_mode(map : String) -> String:
	return blend_modes.get(map, "normal")


func get_layer_material_in() -> Reference:
	if parent.get_script() == get_script():
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
