extends Resource

"""
A material made out of several MaterialLayers

`layers` contains the `MaterialLayers`, each of which can have multiple channels enabled. When baking the results, all `LayerTexture`s of each channel are blended together and stored in the `results` `Dictionary`. It stores the blended `ImageTexture`s with the channel names as keys.
"""

export var layers : Array

var results : Dictionary

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const BlendingLayer = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd").Layer

func generate_results(result_size : Vector2) -> void:
	for map in Globals.TEXTURE_MAP_TYPES:
		generate_map_result(map, result_size)


func generate_map_result(map : String, result_size : Vector2) -> void:
	var blending_layers := []
	
	for layer in layers:
		if not (map in layer.properties and layer.properties[map]):
			continue
		var blending_layer := BlendingLayer.new()
		blending_layer.code = "texture({0}, UV).rgb"
		if "mask" in layer.properties and layer.properties.mask:
			blending_layer.mask = layer.properties.mask.result
		blending_layer.uniform_types = ["sampler2D"]
		blending_layer.uniform_values = [layer.properties[map].result]
		blending_layers.append(blending_layer)
	
	if blending_layers.empty():
		return
	
	var result : ViewportTexture = yield(LayerBlendViewportManager.blend(
			blending_layers, result_size, get_instance_id()), "completed")
	if map == "height":
		var normal_texture : ImageTexture = yield(
				NormalMapGenerationViewport.get_normal_map(result), "completed")
		results.normal = normal_texture
	results[map] = result


func export_textures(to_folder : String) -> void:
	for type in results.keys():
		results[type].get_data().save_png(to_folder.plus_file(type) + ".png")
