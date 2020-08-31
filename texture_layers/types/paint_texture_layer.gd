extends "res://texture_layers/texture_layer.gd"

export var painted_image : Image

func _init(_name := "Untitled Paint Texture"):
	name = _name
	painted_image = Image.new()
	painted_image.create(512, 512, false, Image.FORMAT_RGB8)
	painted_image.lock()


func generate_texture() -> void:
	texture = ImageTexture.new()
	texture.create_from_image(painted_image)


func paint_face(face : int, color : Color, mesh : Mesh) -> void:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	var uv_a := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0))
	var uv_b := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1))
	var uv_c := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))
	var bounds := get_triangle_bounds(uv_a, uv_b, uv_c)
	bounds.position *= painted_image.get_size()
	bounds.size *= painted_image.get_size()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			if Geometry.point_is_inside_triangle(Vector2(x, y) / painted_image.get_size(), uv_a, uv_b, uv_c):
				painted_image.set_pixel(x, y, color)


static func get_triangle_bounds(a : Vector2, b : Vector2, c : Vector2) -> Rect2:
	var bounds := Rect2()
	bounds = bounds.expand(a)
	bounds = bounds.expand(b)
	bounds = bounds.expand(c)
	return bounds
