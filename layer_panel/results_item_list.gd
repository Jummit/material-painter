extends ItemList

"""
A list of map results of the editing `LayerMaterial`
"""

const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")

func load_layer_material(layer : LayerMaterial) -> void:
	clear()
	for map in layer.results:
		add_item(map, layer.results[map])
