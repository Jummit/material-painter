static func paint_face(image : Image, face : int, color : Color, mesh : Mesh) -> void:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	var uv_a := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0))
	var uv_b := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1))
	var uv_c := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))
	var bounds := _get_triangle_bounds(uv_a, uv_b, uv_c)
	var size := image.get_size()
	bounds.position *= size
	bounds.size *= size
	for i in bounds.size.x * bounds.size.y:
		var x := int(bounds.position.y + i % int(bounds.size.x) - 1)
		var y := int(bounds.position.x + i / bounds.size.x - 1)
		if Geometry.point_is_inside_triangle(Vector2(x, y) / size, uv_a, uv_b, uv_c):
			image.set_pixel(x, y, color)


static func _get_triangle_bounds(a : Vector2, b : Vector2, c : Vector2) -> Rect2:
	var bounds := Rect2()
	bounds = bounds.expand(a)
	bounds = bounds.expand(b)
	bounds = bounds.expand(c)
	return bounds
