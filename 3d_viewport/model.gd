extends MeshInstance

"""
The mesh that is used to preview the generated material
"""

signal mesh_changed

const LayerMaterial = preload("res://resources/layer_material.gd")

func set_mesh(to) -> void:
	mesh = to
	set_surface_material(0, preload("res://3d_viewport/material.tres"))
	emit_signal("mesh_changed")


func load_layer_material_maps(layer_material : LayerMaterial) -> void:
	var material_maps = Globals.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	for map in material_maps:
		if map in layer_material.results.keys():
			get_surface_material(0).set(map + "_enabled", true)
			get_surface_material(0).set(map + "_texture", layer_material.results[map])
		else:
			get_surface_material(0).set(map + "_enabled", false)
			get_surface_material(0).set(map + "_texture", null)
		
		if map == "metallic":
			get_surface_material(0).set("metallic", int(map in layer_material.results.keys()))
