extends MeshInstance

"""
The mesh that is used to preview the generated material
"""

const LayerMaterial = preload("res://layers/layer_material.gd")

func load_layer_material_maps(layer_material : LayerMaterial) -> void:
	var material_maps = Globals.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	for map in Globals.TEXTURE_MAP_TYPES:
		if map in layer_material.results.keys():
			get_surface_material(0).set(map + "_texture", layer_material.results[map])
