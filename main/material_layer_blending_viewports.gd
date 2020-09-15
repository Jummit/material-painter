extends Node

const MaterialLayer = preload("res://layers/material_layer.gd")
const LayerMaterial = preload("res://layers/layer_material.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")
const Layer = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd").Layer

#func generate_layer_material_textures(layer_material : LayerMaterial) -> void:
#	# todo: clear all maps before applying, as some may have been removed
#	for type in Globals.TEXTURE_MAP_TYPES:
#		generate_layer_material_channel_texture(layer_material, type)
#
#
#func generate_layer_material_channel_texture(layer_material : LayerMaterial, type : String) -> void:
#	var layers := []
#
#	for layer in layer_material.layers:
#		if not (type in layer.properties and layer.properties[type]):
#			continue
#		var shader_layer := Layer.new()
#		shader_layer.code = "texture({0}, UV).rgb"
#		if "mask" in layer.properties and layer.properties.mask:
#			shader_layer.mask = layer.properties.mask.result
#		shader_layer.uniform_types = ["sampler2D"]
#		shader_layer.uniform_values = [layer.properties[type].result]
#		layers.append(shader_layer)
#
#	if layers.empty():
#		return
#
#	var result : Texture = yield(layer_blending_viewport.blend(layers, result_size), "completed")
#	if type == "height":
#		var normal_texture : ImageTexture = yield(normal_map_generation_viewport.get_normal_map(result), "completed")
#		model.get_surface_material(0).normal_texture = normal_texture
#		layer_material.results.normal = normal_texture
#	else:
#		model.get_surface_material(0).set(type + "_texture", result)
#		layer_material.results[type] = result
#
#
#func generate_texture_layer_result(texture_layer : TextureLayer) -> void:
#	texture_layer.result = yield(layer_blending_viewport.blend(
#			[texture_layer._get_as_shader_layer()], result_size), "completed")
#
#
#func generate_layer_texture_result(layer_texture : LayerTexture) -> void:
#	var layers := []
#	for layer in layer_texture.layers:
#		layers.append(layer._get_as_shader_layer())
#	layer_texture.result = yield(layer_blending_viewport.blend(layers, result_size), "completed")
