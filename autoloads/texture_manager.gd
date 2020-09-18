extends Node

var textures := []

const LayerMaterial = preload("res://layers/layer_material.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")

func load_textures_from_layer_material(layer_material : LayerMaterial) -> void:
	textures.clear()
	for material_layer in layer_material.layers:
		material_layer = material_layer as MaterialLayer
		for map in material_layer.maps:
			if not textures.has(map):
				textures.append(map)
		if material_layer.mask and not material_layer.mask in textures:
			textures.append(material_layer.mask)
