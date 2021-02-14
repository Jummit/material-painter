static func get_steep_edges(mesh : Mesh, threshold := 1.0) -> PoolIntArray:
	var steep : PoolIntArray = []
	
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, 0)
	
	for edge in data_tool.get_edge_count():
		var faces := data_tool.get_edge_faces(edge)
		if faces.size() < 2:
			continue
		var f1 := faces[0]
		var f2 := faces[1]
		var n1 := Plane(
				data_tool.get_vertex(data_tool.get_face_vertex(f1, 0)),
				data_tool.get_vertex(data_tool.get_face_vertex(f1, 1)),
				data_tool.get_vertex(data_tool.get_face_vertex(f1, 2))).normal
		var n2 := Plane(
				data_tool.get_vertex(data_tool.get_face_vertex(f2, 0)),
				data_tool.get_vertex(data_tool.get_face_vertex(f2, 1)),
				data_tool.get_vertex(data_tool.get_face_vertex(f2, 2))).normal
		if abs(n1.angle_to(n2)) > threshold:
			steep.append(edge)
	
	return steep


static func get_connected_geometry(data_tool : MeshDataTool,
		edge_blacklist := {}) -> Array:
	var ids := []
	var checked := {}
	for face in data_tool.get_face_count():
		if not face in checked:
			var connected := _get_connected_faces(data_tool, face, edge_blacklist)
			for connected_face in connected:
				checked[connected_face] = true
			ids.append(connected)
	return ids


static func uv_to_vertex_positions(mesh : Mesh, surface : int) -> Mesh:
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, surface)
	for vertex in data_tool.get_vertex_count():
		var uv := data_tool.get_vertex_uv(vertex)
		data_tool.set_vertex(vertex, Vector3(uv.x, uv.y, 0))
	var new_mesh := Mesh.new()
	data_tool.commit_to_surface(new_mesh)
	return new_mesh


static func get_quads(data_tool : MeshDataTool) -> Dictionary:
	var quads := {}

	for face in data_tool.get_face_count():
		if face in quads:
			continue
		var longest : int
		var longest_lenght := -INF
		for edge in 3:
			var face_edge := data_tool.get_face_edge(face, edge)
			var lenght := data_tool.get_vertex(data_tool.get_edge_vertex(
						face_edge, 0)).distance_to(data_tool.get_vertex(
						data_tool.get_edge_vertex(face_edge, 1)))
			if lenght > longest_lenght:
				longest = face_edge
				longest_lenght = lenght
		var edge_faces := data_tool.get_edge_faces(longest)
		if edge_faces.size() < 2:
			continue
		var other : int
		for edge_face in edge_faces:
			other = edge_face
			if other != face:
				break
		quads[other] = face
	
	return quads


static func join_duplicates(mesh : Mesh, surface : int) -> Dictionary:
	var data_tool := MeshDataTool.new()
	if not data_tool.create_from_surface(_deindex(mesh), surface) == OK:
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
			original_face_ids[last_face_id] = data_tool.get_vertex_faces(
					vertex_id)[0]
			last_face_id += 1
		surface_tool.add_index(vertex_ids[vertex])
	return {
			mesh = surface_tool.commit(),
			original_face_ids = original_face_ids}


static func _deindex(mesh : Mesh) -> Mesh:
	var new_mesh := Mesh.new()
	var surface_tool := SurfaceTool.new()
	for surface in mesh.get_surface_count():
		surface_tool.create_from(mesh, surface)
		surface_tool.deindex()
		surface_tool.commit(new_mesh)
	return new_mesh


static func _get_normal(a : Vector3, b : Vector3, c : Vector3) -> Vector3:
	return Plane(a, b, c).normal


static func _get_connected_faces(data_tool : MeshDataTool, face : int,
		edge_blacklist : Dictionary) -> PoolIntArray:
	var to_check := []
	var current := face
	var checked := {}
	
	while true:
		for edge_count in 3:
			var edge := data_tool.get_face_edge(current, edge_count)
			if edge in edge_blacklist:
				continue
			for connected_face in data_tool.get_edge_faces(edge):
				if not connected_face == current and\
						not connected_face in checked and\
						not connected_face in to_check:
					to_check.append(connected_face)
		checked[current] = true
		if to_check.empty():
			break
		current = to_check.pop_front()
	
	var connected : PoolIntArray = []
	for face in checked:
		connected.append(face)
	
	return connected
