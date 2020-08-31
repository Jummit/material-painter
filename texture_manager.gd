extends Node

const LayerMaterial = preload("res://material_layers/layer_material.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

var textures := []

func load_textures_from_layer_material(layer_material : LayerMaterial) -> void:
	textures.clear()
	for material_layer in layer_material.layers:
		for key in material_layer.properties.keys():
			if material_layer.properties[key] is LayerTexture:
				var layer_texture : LayerTexture = material_layer.properties[key]
				if not textures.has(layer_texture):
					textures.append(layer_texture)
