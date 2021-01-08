extends "res://viewport/viewport.gd"

func _prepare_mesh(mesh : Mesh) -> Mesh:
	return preload("res://addons/selection_utils/mesh_utils.gd").uv_to_vertex_positions(mesh)
