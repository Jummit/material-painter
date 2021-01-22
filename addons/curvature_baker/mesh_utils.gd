class Vertex:
	var vertex : Vector3
	var id : int
	func _init(_vertex, _id) -> void:
		id = _id
		vertex = _vertex

class VertexSorter:
	static func sort(a : Vertex, b : Vertex) -> bool:
		return a.vertex > b.vertex

static func join_duplicates(mesh : Mesh) -> Dictionary:
	var data_tool := MeshDataTool.new()
	if not data_tool.create_from_surface(mesh, 0) == OK:
		return {}
	
	var ordered_vertices := []
	for vertex_id in data_tool.get_vertex_count():
		var vertex := data_tool.get_vertex(vertex_id)
		ordered_vertices.append(Vertex.new(vertex, vertex_id))
	ordered_vertices.sort_custom(VertexSorter, "sort")
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var original_ids := {}
	var new_ids := {}
	var current_id := -1
	var last_vertex
	
	for vertex in ordered_vertices:
		if not last_vertex or not last_vertex.is_equal_approx(vertex.vertex):
			surface_tool.add_color(Color(vertex.id))
			surface_tool.add_vertex(vertex.vertex)
			current_id += 1
			last_vertex = vertex.vertex
			original_ids[current_id] = []
		original_ids[current_id].append(vertex.id)
		new_ids[vertex.id] = current_id
	
	for face in data_tool.get_face_count():
		for v in [
				data_tool.get_face_vertex(face, 0),
				data_tool.get_face_vertex(face, 1),
				data_tool.get_face_vertex(face, 2)]:
			surface_tool.add_index(new_ids[v])
	
	return {
			mesh = surface_tool.commit(),
			original_ids = original_ids}


static func get_texel_density(mesh : Mesh) -> float:
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, 0)
	var v1 := data_tool.get_edge_vertex(0, 0)
	var v2 := data_tool.get_edge_vertex(0, 1)
	var world_length := data_tool.get_vertex(v1).distance_to(data_tool.get_vertex(v2))
	var texture_length := data_tool.get_vertex_uv(v1).distance_to(data_tool.get_vertex_uv(v2))
	return world_length / texture_length
