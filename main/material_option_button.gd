extends OptionButton

"""
`OptionButton` used to switch between surfaces of the loaded model
"""

var mesh : Mesh setget set_mesh

const LayerMaterial = preload("res://resources/material/layer_material.gd")

func set_mesh(to : Mesh) -> void:
	mesh = to
	clear()
	for surface in mesh.get_surface_count():
		var mat := mesh.surface_get_material(surface)
		var material_name : String = "Material %s" % surface
		if mat:
			material_name = mat.resource_name
		add_item(material_name)
