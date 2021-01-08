extends MeshInstance

"""
The mesh that is used to preview the generated material

Also used for material thumbnails in the asset browser.
If `isolated_map` is specified it will be used as albedo.
"""

# the name of the currently viewing map, for example "albedo"
var isolated_map : String

func _ready() -> void:
	Globals.connect("editing_layer_material_changed", self,
			"_on_Globals_editing_layer_material_changed")
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")


func load_materials(layer_materials : Array) -> void:
	if not isolated_map:
		for surface in layer_materials.size():
			set_surface_material(surface, layer_materials[surface].get_material(
					get_surface_material(surface)))


func _on_ResultsItemList_map_selected(map : String) -> void:
	if map == isolated_map:
		isolated_map = ""
		load_materials(Globals.current_file.layer_materials)
	else:
		isolated_map = map
		for material_num in Globals.current_file.layer_materials.size():
			var results : Dictionary = Globals.current_file.layer_materials[\
					material_num].results
			if map in results:
				var material := SpatialMaterial.new()
				material.albedo_texture = results[map]
				material.flags_albedo_tex_force_srgb = true
				set_surface_material(material_num, material)


func _on_Globals_mesh_changed(to : Mesh) -> void:
	mesh = to


func _on_Globals_editing_layer_material_changed() -> void:
	if not Globals.editing_layer_material.is_connected("results_changed", self,
			"_on_LayerMaterial_results_changed"):
		Globals.editing_layer_material.connect("results_changed", self,
				"_on_LayerMaterial_results_changed")


func _on_LayerMaterial_results_changed() -> void:
	load_materials(Globals.current_file.layer_materials)
