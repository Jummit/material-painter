extends "res://addons/selection_utils/selection_type.gd"

static func prepare_mesh(mesh : Mesh) -> Mesh:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	
	for face in mesh_tool.get_face_count():
		var color := Color(float(face) / float(mesh_tool.get_face_count()), 0, 0);
		for v in 3:
			mesh_tool.set_vertex_color(mesh_tool.get_face_vertex(face, v), color)
	
	var array_mesh := ArrayMesh.new()
	mesh_tool.commit_to_surface(array_mesh)
	return array_mesh
