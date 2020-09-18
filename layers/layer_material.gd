extends Resource

"""
A material made out of several MaterialLayers

`layers` contains the `MaterialLayers`, each of which can have multiple channels enabled. When baking the results, all `LayerTexture`s of each channel are blended together and stored in the `results` `Dictionary`. It stores the blended `ImageTexture`s with the channel names as keys.
"""

export var layers : Array

var results : Dictionary

const TextureLayer = preload("res://layers/texture_layer.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const BlendingLayer = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const LayerTexture = preload("res://layers/layer_texture.gd")

func _init() -> void:
	resource_local_to_scene = true


func update_results(result_size : Vector2, generate_texture_layers := false) -> void:
	for map in Globals.TEXTURE_MAP_TYPES:
		update_map_result(map, result_size, generate_texture_layers)


func update_map_result(map : String, result_size : Vector2, generate_texture_layers := false) -> void:
	var blending_layers := []
	
	for layer in layers:
		layer = layer as MaterialLayer
		if not (map in layer.maps and layer.maps[map]):
			continue
		
		var map_layer_texture : LayerTexture = layer.maps[map]
		if generate_texture_layers:
			map_layer_texture.update_result(result_size)
		
		var blending_layer := BlendingLayer.new()
		if layer.mask:
			blending_layer.mask = layer.mask.result
		blending_layer.code = "texture({0}, UV).rgb"
		blending_layer.uniform_types = ["sampler2D"]
		blending_layer.uniform_values = [map_layer_texture.result]
		blending_layers.append(blending_layer)
	
	if blending_layers.empty():
		return
	
	var result : ViewportTexture = yield(LayerBlendViewportManager.blend(
			blending_layers, result_size, get_instance_id()), "completed")
	if map == "height":
		var normal_texture : ViewportTexture = yield(
				NormalMapGenerationViewport.get_normal_map(result), "completed")
		results.normal = normal_texture
	results[map] = result


func export_textures(to_folder : String) -> void:
	for type in results.keys():
		results[type].get_data().save_png(to_folder.plus_file(type) + ".png")


func get_depending_layer_textures(texture_layer : TextureLayer) -> Array:
	var depending_layer_textures := []
	for layer in layers:
		layer = layer as MaterialLayer
		depending_layer_textures += layer.get_depending_layer_textures(texture_layer)
	return depending_layer_textures
