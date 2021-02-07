extends MeshInstance

"""
The mesh that is used to preview the generated material

Also used for material thumbnails in the asset browser.
If `isolated_map` is specified it will be used as albedo.
"""

# the name of the currently viewing map, for example "albedo"
var isolated_map : String setget set_isolated_map

func _ready() -> void:
	Constants.connect("current_layer_material_changed", self,
			"_on_Constants_current_layer_material_changed")


func load_materials(layer_materials : Array) -> void:
	if not isolated_map:
		for surface in layer_materials.size():
			set_surface_material(surface, layer_materials[surface].get_material(
					get_surface_material(surface)))


func set_isolated_map(to : String) -> void:
	isolated_map = to
	if isolated_map:
		for material_num in Constants.current_file.layer_materials.size():
			var results : Dictionary = Constants.current_file.layer_materials[\
					material_num].results
			if isolated_map in results:
				var material := SpatialMaterial.new()
				material.albedo_texture = results[isolated_map]
				material.flags_albedo_tex_force_srgb = true
				set_surface_material(material_num, material)
	else:
		load_materials(Constants.current_file.layer_materials)


func _on_Constants_current_layer_material_changed() -> void:
	if not Constants.current_layer_material.is_connected("results_changed", self,
			"_on_LayerMaterial_results_changed"):
		Constants.current_layer_material.connect("results_changed", self,
				"_on_LayerMaterial_results_changed")


func _on_LayerMaterial_results_changed() -> void:
	load_materials(Constants.current_file.layer_materials)
