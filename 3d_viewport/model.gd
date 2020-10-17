extends MeshInstance

"""
The mesh that is used to preview the generated material
"""

signal mesh_changed

const LayerMaterial = preload("res://resources/layer_material.gd")

func set_mesh(to) -> void:
	mesh = to
	emit_signal("mesh_changed")


func load_layer_materials(layer_materials : Array) -> void:
	var material_maps = Globals.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	
	for layer_material_count in layer_materials.size():
		if not get_surface_material(layer_material_count):
			set_surface_material(layer_material_count, preload("res://3d_viewport/material.tres").duplicate())
		var material := get_surface_material(layer_material_count)
		var layer_material : LayerMaterial = layer_materials[layer_material_count]
		
		for map in material_maps:
			if map in layer_material.results.keys():
				material.set(map + "_enabled", true)
				material.set(map + "_texture", layer_material.results[map])
			else:
				material.set(map + "_enabled", false)
				material.set(map + "_texture", null)
			
			if map == "metallic":
				material.set("metallic", int(map in layer_material.results.keys()))


func load_albedo_textures(textures : Array) -> void:
	for texture_num in textures.size():
		var material := SpatialMaterial.new()
		material.albedo_texture = textures[texture_num]
		material.flags_albedo_tex_force_srgb = true
		set_surface_material(texture_num, material)
