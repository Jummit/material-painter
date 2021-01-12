extends OptionButton

"""
`OptionButton` used to switch between surfaces of the loaded model
"""

func _ready():
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")


func _on_Globals_mesh_changed(mesh : Mesh) -> void:
	clear()
	for surface in Globals.current_file.layer_materials.size():
		var mat := mesh.surface_get_material(surface)
		var material_name : String = "Material %s" % surface
		if mat:
			material_name = mat.resource_name
		add_item(material_name)
