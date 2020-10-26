extends Viewport

func generate_id_map(mesh : Mesh, result_size : Vector2) -> ViewportTexture:
	var original_data_tool := MeshDataTool.new()
	original_data_tool.create_from_surface(mesh, 0)
	
	var data_tool := MeshDataTool.new()
	var joined_data := _join_duplicates(mesh)
	data_tool.create_from_surface(joined_data.mesh, 0)
	
	var ids := []
	var already_added_faces := []
	for face in data_tool.get_face_count():
		if not face in already_added_faces:
			ids.append(_get_connected_faces(data_tool, face, already_added_faces))
	
	for id_num in ids.size():
		for face in ids[id_num]:
			var color := Color().from_hsv(float(id_num) / float(ids.size()), 1.0, 1.0)
			for vertex in 3:
				original_data_tool.set_vertex_color(original_data_tool.get_face_vertex(face, vertex), color)
	
	var new_mesh := Mesh.new()
	original_data_tool.commit_to_surface(new_mesh)
	size = result_size
	$MeshInstance.mesh = new_mesh
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()


static func _get_connected_faces(data_tool : MeshDataTool, face : int, already_added_faces : Array) -> PoolIntArray:
	var connected : PoolIntArray = [face]
	already_added_faces.append(face)
	for edge in 3:
		var connected_faces : Array = data_tool.get_edge_faces(data_tool.get_face_edge(face, edge))
		connected_faces.erase(face)
		for connected_face in connected_faces:
			if not connected_face in already_added_faces:
				connected += _get_connected_faces(data_tool, connected_face, already_added_faces)
	return connected


static func _get_triangle_bounds(a : Vector2, b : Vector2, c : Vector2) -> Rect2:
	var bounds := Rect2()
	bounds = bounds.expand(a)
	bounds = bounds.expand(b)
	bounds = bounds.expand(c)
	return bounds


static func _join_duplicates(mesh : Mesh) -> Dictionary:
	var data_tool := MeshDataTool.new()
	if not data_tool.create_from_surface(mesh, 0) == OK:
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
