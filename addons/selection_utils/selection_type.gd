extends Reference

static func prepare_mesh(mesh : Mesh, _surface : int) -> Mesh:
	return mesh

static func get_color() -> Color:
	return Color(randf(), randf(), randf())
