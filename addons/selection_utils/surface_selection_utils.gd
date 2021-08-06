extends Viewport

var mesh : ArrayMesh setget set_mesh

func set_mesh(to):
	mesh = _prepare_mesh(to)
	$MeshInstance.mesh = mesh


func update_viewport(viewport : Viewport) -> void:
	size = viewport.size
	screen_sample_viewport.size = viewport.size
	screen_viewport_texture.rect_size = viewport.size
	sample_camera.global_transform = viewport.get_camera().global_transform
	sample_camera.fov = viewport.get_camera().fov
	sample_camera.far = viewport.get_camera().far
	sample_camera.near = viewport.get_camera().near


static func _prepare_mesh(mesh : ArrayMesh) -> ArrayMesh:
	var data_tool := MeshDataTool.new()
	var result := ArrayMesh.new()
	var surface_count := mesh.get_surface_count()
	for surface in surface_count:
		data_tool.create_from_surface(mesh, surface)
		for vertex in data_tool.get_vertex_count():
			data_tool.set_vertex_color(vertex, Color(
					float(surface) / surface_count))
		data_tool.commit_to_surface(result)
	return result
