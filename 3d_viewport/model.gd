extends MeshInstance

"""
The mesh that is used to preview the generated material
"""

# the name of the currently viewing map, for example "albedo"
var isolated_map : String

onready var main : Control = $"../../../../../../../../../.."

func load_materials(layer_materials : Array) -> void:
	for surface in layer_materials.size():
		set_surface_material(surface, layer_materials[surface].get_material(get_surface_material(surface)))


func _on_ResultsItemList_map_selected(map : String) -> void:
	if map == isolated_map:
		isolated_map = ""
		load_materials(main.current_file.layer_materials)
	else:
		isolated_map = map
		for material_num in main.current_file.layer_materials.size():
			var results : Dictionary = main.current_file.layer_materials[material_num].results
			if map in results:
				var material := SpatialMaterial.new()
				material.albedo_texture = results[map]
				material.flags_albedo_tex_force_srgb = true
				set_surface_material(material_num, material)
