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

signal results_changed

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")

func _init() -> void:
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer in layers:
		layer.parent = self


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
	emit_signal("results_changed")


func update_all_layer_textures(result_size : Vector2) -> void:
	var flat_layers := get_flat_layers(layers, false)
	for layer in flat_layers:
		var result = layer.update_all_layer_textures(result_size)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")


func get_flat_layers(layer_array : Array = layers, add_hidden := true) -> Array:
	var flat_layers := []
	for layer in layer_array:
		if (not add_hidden) and not layer.visible:
			continue
		if layer is MaterialFolder:
			flat_layers += get_flat_layers(layer.layers, add_hidden)
		else:
			flat_layers.append(layer)
	return flat_layers


func get_material(existing : SpatialMaterial = null) -> SpatialMaterial:
	var material_maps = Globals.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	
	var material : SpatialMaterial = existing
	if not existing:
		material = preload("res://3d_viewport/material.tres").duplicate()
	
	for map in material_maps:
		if map in results.keys():
			material.set(map + "_enabled", true)
			material.set(map + "_texture", results[map])
		else:
			material.set(map + "_enabled", false)
			material.set(map + "_texture", null)
		
		if map == "metallic":
			material.set("metallic", int(map in results.keys()))
	
	return material


func add_layer(layer, onto) -> void:
	layer.parent = onto
	onto.layers.append(layer)
	if layer.has_method("get_layer_texture_in"):
		yield(layer.get_layer_texture_in().update_result(Globals.result_size), "completed")
	else:
		if layer.get_script() == load("res://resources/material/material_layer.gd"):
			var result = layer.update_all_layer_textures(Globals.result_size)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		else:
			var result = _update_all_layer_textures(layer.layers)
			if result is GDScriptFunctionState:
				yield(result, "completed")
	update_results(Globals.result_size)


func delete_layer(layer) -> void:
	layer.parent.layers.erase(layer)
	if layer.has_method("get_layer_texture_in"):
		yield(layer.get_layer_texture_in().update_result(Globals.result_size), "completed")
	update_results(Globals.result_size, false)


func _update_all_layer_textures(layers_to_update : Array) -> void:
	for layer in layers_to_update:
		if layer.get_script() == load("res://resources/material/layer_material.gd"):
			yield(layer.update_all_layer_textures(Globals.result_size), "completed")
		else:
			yield(_update_all_layer_textures(layer.layers), "completed")


func update(update_icons := true, use_cached_shader := false) -> void:
	var result = update_results(Globals.result_size, use_cached_shader)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	emit_signal("changed", update_icons, use_cached_shader)
