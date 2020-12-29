extends "res://addons/selection_utils/selection_type.gd"

static func prepare_mesh(mesh : Mesh) -> Mesh:
	var joined_data := _join_duplicates(mesh)
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(joined_data.mesh, 0)
	var original_mesh_tool := MeshDataTool.new()
	original_mesh_tool.create_from_surface(mesh, 0)
	
	var quads := {}
	
	for face in mesh_tool.get_face_count():
		if face in quads:
			continue
		var longest : int
		var longest_lenght := -INF
		for edge in 3:
			var face_edge := mesh_tool.get_face_edge(face, edge)
			var lenght := mesh_tool.get_vertex(mesh_tool.get_edge_vertex(
						face_edge, 0)).distance_to(mesh_tool.get_vertex(
						mesh_tool.get_edge_vertex(face_edge, 1)))
			if lenght > longest_lenght:
				longest = face_edge
				longest_lenght = lenght
		var edge_faces := mesh_tool.get_edge_faces(longest)
		if edge_faces.size() < 2:
			continue
		var other : int
		for edge_face in edge_faces:
			other = edge_face
			if other != face:
				break
		quads[other] = face
	
	for v in mesh_tool.get_vertex_count():
		mesh_tool.set_vertex(v, mesh_tool.get_vertex(v) + Vector3(randf(),randf(),randf()) / 7)
	for v in original_mesh_tool.get_vertex_count():
		original_mesh_tool.set_vertex(v, original_mesh_tool.get_vertex(v) + Vector3(randf(),randf(),randf()) / 7)
	
	var face : int
	var color : Color
	for face_count in quads.size():
		face = quads.keys()[face_count]
		color = Color(float(face_count) / quads.size(), 0, 0);
		for v in 3:
			original_mesh_tool.set_vertex_color(
					original_mesh_tool.get_face_vertex(
					joined_data.original_face_ids[face], v), color)
			original_mesh_tool.set_vertex_color(
					original_mesh_tool.get_face_vertex(
					joined_data.original_face_ids[quads[face]], v), color)
	
	var array_mesh := ArrayMesh.new()
#	mesh_tool.commit_to_surface(array_mesh)
	original_mesh_tool.commit_to_surface(array_mesh)
	return array_mesh


static func _join_duplicates(mesh : Mesh) -> Dictionary:
	var data_tool := MeshDataTool.new()
	var deindex_surface_tool := SurfaceTool.new()
	deindex_surface_tool.create_from(mesh, 0)
	deindex_surface_tool.deindex()
	if not data_tool.create_from_surface(deindex_surface_tool.commit(), 0) == OK:
		return {}
	
	var old_vertex_ids := {}
	var ordered_vertices := []
	for vertex_id in data_tool.get_vertex_count():
		var vertex := data_tool.get_vertex(vertex_id)
		old_vertex_ids[vertex] = vertex_id
		ordered_vertices.append(vertex)
	ordered_vertices.sort()
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.index()
	
	var vertex_ids := {}
	var original_face_ids := {}
	var current_id := 0
	var last_vertex : Vector3 = ordered_vertices.front()
	var id : int = old_vertex_ids[ordered_vertices.front()]
	surface_tool.add_color(Color(id))
	surface_tool.add_vertex(last_vertex)
	
	for vertex in ordered_vertices:
		if not last_vertex.is_equal_approx(vertex):
			id = old_vertex_ids[vertex]
			surface_tool.add_color(Color(id))
			surface_tool.add_vertex(vertex)
			current_id += 1
			last_vertex = vertex
		vertex_ids[vertex] = current_id
	
	var last_face_id := 0
	for vertex_id in data_tool.get_vertex_count():
		var vertex := data_tool.get_vertex(vertex_id)
		if vertex_id % 3 == 0:
			original_face_ids[last_face_id] = data_tool.get_vertex_faces(vertex_id)[0]
			last_face_id += 1
		surface_tool.add_index(vertex_ids[vertex])
	return {
			mesh = surface_tool.commit(),
			original_face_ids = original_face_ids}
