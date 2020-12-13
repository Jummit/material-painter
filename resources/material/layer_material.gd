extends Resource

"""
A material whose maps are generated by blending several `MaterialLayers`

`layers` contains the `MaterialLayers`, each of which
can have multiple channels enabled.
When generating the results, all `LayerTexture`s of each map
are blended together and stored in the `results` `Dictionary`.
It stores the blended `Texture`s with the map names as keys.

To make it possible to use Viewports inside of sub-resources of MaterialLayers,
this and every `Resource` class that is used inside of it has to be local to scene.
"""

export var layers : Array

var results : Dictionary

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const FolderLayer = preload("res://resources/texture/texture_folder.gd")

func _init() -> void:
	resource_local_to_scene = true


func update_results(result_size : Vector2, use_cached_shader := false) -> void:
	var flat_layers := get_flat_layers(layers, false)
	for map in Globals.TEXTURE_MAP_TYPES:
		var blending_layers := []
		for layer in flat_layers:
			if not (map in layer.maps and layer.maps[map]):
				continue
			var map_layer_texture : LayerTexture = layer.maps[map]
			map_layer_texture.update_result(result_size, true, use_cached_shader)
			
			var blending_layer : BlendingLayer
			if layer.mask:
				layer.mask.update_result(result_size, true, use_cached_shader)
				blending_layer = BlendingLayer.new("texture({layer_result}, uv)", "normal", 1.0, layer.mask.result)
			else:
				blending_layer = BlendingLayer.new("texture({layer_result}, uv)")
			blending_layer.uniform_types.append("sampler2D")
			blending_layer.uniform_names.append("layer_result")
			blending_layer.uniform_values.append(map_layer_texture.result)
			blending_layers.append(blending_layer)
		
		if blending_layers.empty():
			results.erase(map)
			continue
		
		var result : Texture = yield(LayerBlendViewportManager.blend(
				blending_layers, result_size, get_instance_id() + map.hash(), use_cached_shader), "completed")
		
		if map == "height":
			map = "normal"
			result = yield(NormalMapGenerationViewport.get_normal_map(result), "completed")
		results[map] = result


func update_all_layer_textures(result_size : Vector2) -> void:
	var flat_layers := get_flat_layers(layers, false)
	for layer in flat_layers:
		var result = layer.update_all_layer_textures(result_size)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")


func is_inside_layer_texture(layer) -> bool:
	return get_layer_texture_of_texture_layer(layer)


func get_layer_texture_of_texture_layer(texture_layer):
	for layer in get_flat_layers():
		var layer_texture = layer.get_layer_texture_of_texture_layer(texture_layer)
		if layer_texture:
			return layer_texture


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


func get_parent(layer):
	if layer in layers:
		return self
	else:
		for folder in get_folders():
			if layer in folder.layers:
				return folder
	for material_layer in get_flat_layers():
		for layer_texture in material_layer.get_layer_textures():
			if layer_texture == layer:
				return material_layer
			if layer in layer_texture.layers:
				return layer_texture
			for folder in layer_texture.get_folders():
				if layer in folder.layers:
					return folder
