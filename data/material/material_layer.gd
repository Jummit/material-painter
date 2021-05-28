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

var maps : Dictionary setget set_maps
var mask : Reference setget set_mask
var name : String
var visible := true
var is_folder := false
var opacities : Dictionary
var blend_modes : Dictionary
var layers : Array

var results : Dictionary
var parent : Reference
var dirty := true

const TextureLayer = preload("res://data/texture/texture_layer.gd")
const LayerTexture = preload("res://data/texture/layer_texture.gd")
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}) -> void:
	name = data.get("name", "")
	visible = data.get("visible", true)
	opacities = data.get("opacities", {})
	blend_modes = data.get("blend_modes", {})
	is_folder = data.get("folder", false)
	if mask in data:
		set_mask(LayerTexture.new(data.mask))
	for map in data.get("maps", {}):
		maps[map] = LayerTexture.new(data.maps[map])
	set_maps(maps)
	for layer in data.get("layers", []):
		add_layer(get_script().new(layer))
	name = "Untitled Folder" if is_folder else "Untitled Layer"


func serialize() -> Dictionary:
	var data := {
		maps = {},
		layers = [],
		name = name,
		opacities = opacities,
		blend_modes = blend_modes,
		visible = visible,
		is_folder = is_folder,
	}
	if mask:
# warning-ignore:unsafe_method_access
		data.mask = mask.serialize()
	for map in maps:
		data.maps[map] = maps[map].serialize()
	for layer in layers:
		data.layers.append(layer.serialize())
	return data


func get_opacity(map : String) -> float:
	return opacities.get(map, 1.0)


func get_blend_mode(map : String) -> float:
	return blend_modes.get(map, "normal")


func set_maps(to):
	maps = to
	for map in maps.values():
		map.parent = self


func add_layer(layer) -> void:
	layers.append(layer)
	layer.parent = self


func set_mask(to):
	mask = to
	if mask:
# warning-ignore:unsafe_property_access
		mask.parent = self


func update(context : MaterialGenerationContext, force_all := false) -> void:
	if not dirty and not force_all:
		return
	if is_folder:
		for layer in layers:
			var result = layer.update(context, force_all)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
		
		if mask:
# warning-ignore:unsafe_method_access
			var result = mask.update(context, force_all)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		
		for map in Constants.TEXTURE_MAP_TYPES:
			var blending_layers := []
			for layer in layers:
				var map_result : Texture = layer.get_map_result(map)
				if not map_result or not layer.visible:
					continue
				
				var blending_layer : BlendingLayer
				if layer.mask:
					blending_layer = BlendingLayer.new(
						"texture({layer_result}, uv)",
						"normal", 1.0, layer.mask.result)
				else:
					blending_layer = BlendingLayer.new("texture({layer_result}, uv)")
				blending_layer.uniform_types.append("sampler2D")
				blending_layer.uniform_names.append("layer_result")
				blending_layer.uniform_values.append(map_result)
				blending_layers.append(blending_layer)
			
			if blending_layers.empty():
				results.erase(map)
				continue
			
			var result : Texture = yield(context.blending_viewport_manager.blend(
					blending_layers, context.result_size,
					get_instance_id() + map.hash()), "completed")
			
			results[map] = result
	else:
		for layer in get_layer_textures():
			var result = layer.update(context, force_all)
			if result is GDScriptFunctionState:
				yield(result, "completed")
	dirty = false


func get_layer_material_in() -> Reference:
# warning-ignore:unsafe_property_access
	if "is_folder" in parent and parent.is_folder:
# warning-ignore:unsafe_method_access
		return parent.get_layer_material_in()
	else:
		return parent


func get_layer_textures() -> Array:
	var layer_textures := maps.values()
	if mask:
		layer_textures.append(mask)
	return layer_textures


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
# warning-ignore:unsafe_method_access
	get_layer_material_in().mark_dirty(shader_dirty)


func get_map_result(map : String) -> Texture:
	if is_folder:
		if not map in results:
			return null
		return results[map]
	else:
		if not map in maps:
			return null
		return maps[map].result


func duplicate() -> Object:
	return get_script().new(serialize())
