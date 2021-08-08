extends "../selection_type.gd"

"""
Selection that separates geometry by mesh islands
"""

const MeshUtils = preload("res://addons/third_party/mesh_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh, surface : int) -> Mesh:
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, surface)
	
	var joined_data := MeshUtils.join_duplicates(mesh, surface)
	
	var sample_data_tool := MeshDataTool.new()
	sample_data_tool.create_from_surface(joined_data.mesh, 0)
	var ids := MeshUtils.get_connected_geometry(sample_data_tool)
	
	for id_num in ids.size():
		var color := get_color()
		for face in ids[id_num]:
			for vertex in 3:
				data_tool.set_vertex_color(data_tool.get_face_vertex(face,
						vertex), color)
	
	var new_mesh := Mesh.new()
	data_tool.commit_to_surface(new_mesh)
	return new_mesh
