extends MeshInstance

"""
The mesh that is used to preview the generated material
"""

signal mesh_changed

const LayerMaterial = preload("res://resources/layer_material.gd")

func set_mesh(to) -> void:
	mesh = to
	emit_signal("mesh_changed")


func load_layer_material_maps(layer_material : LayerMaterial) -> void:
	var material_maps = Globals.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	for map in material_maps:
		if map in layer_material.results.keys():
			material_override.set(map + "_enabled", true)
			material_override.set(map + "_texture", layer_material.results[map])
		else:
			material_override.set(map + "_enabled", false)
			material_override.set(map + "_texture", null)
		
		if map == "metallic":
			material_override.set("metallic", int(map in layer_material.results.keys()))
