extends "res://addons/selection_utils/selection_type.gd"

const MeshUtils = preload("res://addons/mesh_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh, surface : int) -> Mesh:
	var original_data_tool := MeshDataTool.new()
	original_data_tool.create_from_surface(mesh, surface)
	
	var joined_data := MeshUtils.join_duplicates(mesh, surface)
	
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(joined_data.mesh, 0)
	var ids := MeshUtils.get_connected_geometry(data_tool)
	
	for id_num in ids.size():
		var color := get_color()
		for face in ids[id_num]:
			for vertex in 3:
				original_data_tool.set_vertex_color(
						original_data_tool.get_face_vertex(face, vertex), color)
	
	var new_mesh := Mesh.new()
	original_data_tool.commit_to_surface(new_mesh)
	return new_mesh
