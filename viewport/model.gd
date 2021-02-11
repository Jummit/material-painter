extends MeshInstance

"""
The mesh that is used to preview the generated material

Also used for material thumbnails in the asset browser.
If `isolated_map` is specified it will be used as albedo.
"""

var layer_materials : Array setget set_layer_materials
# the name of the currently viewing map, for example "albedo"
var isolated_map : String setget set_isolated_map

func set_layer_materials(to) -> void:
	layer_materials = to
	for layer_material in layer_materials:
		if not layer_material.is_connected("changed", self, "_on_LayerMaterial_changed"):
			layer_material.connect("changed", self, "_on_LayerMaterial_changed")
	_apply_materials()


func set_isolated_map(to : String) -> void:
	isolated_map = to
	if not isolated_map:
		_apply_materials()
		return
	
	for material_num in layer_materials.size():
		var results : Dictionary = layer_materials[material_num].results
		if isolated_map in results:
			var material := SpatialMaterial.new()
			material.albedo_texture = results[isolated_map]
			material.flags_albedo_tex_force_srgb = true
			set_surface_material(material_num, material)


func _apply_materials() -> void:
	if not isolated_map:
		for surface in layer_materials.size():
			set_surface_material(surface, layer_materials[surface].get_material(
					get_surface_material(surface)))


func _on_LayerMaterial_changed() -> void:
	_apply_materials()
