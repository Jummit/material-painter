extends OptionButton

"""
`OptionButton` used to switch between surfaces of the loaded model
"""

func _on_Main_mesh_changed(mesh : Mesh) -> void:
	clear()
	ResourceSaver.save("res://test.mesh", mesh)
	for surface in mesh.get_surface_count():
		var mat := mesh.surface_get_material(surface)
		var material_name : String = "Material %s" % surface
		if mat:
			material_name = mat.resource_name
		add_item(material_name)
