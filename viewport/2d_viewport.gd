extends "res://viewport/viewport.gd"

func _ready() -> void:
	get_parent().title = "2D Viewport"
	painter.paint_through = true


static func _prepare_mesh(to_prepare : Mesh) -> Mesh:
	return uv_to_vertex_positions(to_prepare)


static func uv_to_vertex_positions(mesh : Mesh) -> Mesh:
	var data_tool := MeshDataTool.new()
	var new_mesh := Mesh.new()
	for surface in mesh.get_surface_count():
		data_tool.create_from_surface(mesh, 0)
		for vertex in data_tool.get_vertex_count():
			var uv := data_tool.get_vertex_uv(vertex)
			data_tool.set_vertex(vertex, Vector3(uv.x, 1.0 - uv.y, 0))
		data_tool.commit_to_surface(new_mesh)
	return new_mesh
