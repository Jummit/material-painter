extends TextureRect

onready var model : MeshInstance = $"../3DViewport/Viewport/Model"
onready var texture_layer_panel : VBoxContainer = $"../../../TextureLayerPanel"

const PaintTextureLayer = preload("res://texture_layers/types/paint_texture_layer.gd")

var mesh_tool := MeshDataTool.new()

func _ready() -> void:
	mesh_tool.create_from_surface(model.mesh, 0)


func _draw() -> void:
	for face in mesh_tool.get_face_count():
		var points : PoolVector2Array = []
		for i in 3:
			points.append(mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, i)))
		points.append(points[0])
		points = Transform2D.IDENTITY.scaled(rect_size).xform(points)
		draw_multiline(points, Color.yellow, 2.0)


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if texture_layer_panel.editing_texture_layer is PaintTextureLayer:
			var selected_face := get_selected_face(get_local_mouse_position())
			if selected_face != -1:
				paint_face(selected_face, texture_layer_panel.editing_texture_layer.painted_image, Color.white)
			(texture as ImageTexture).create_from_image(texture_layer_panel.editing_texture_layer.painted_image)


func get_selected_face(position : Vector2) -> int:
	for face in mesh_tool.get_face_count():
		if Geometry.point_is_inside_triangle(position / rect_size,
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))):
			return face
	return -1


func paint_face(face : int, image : Image, color : Color) -> void:
	var uv_a := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0))
	var uv_b := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1))
	var uv_c := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))
	var bounds := get_triangle_bounds(uv_a, uv_b, uv_c)
	bounds.position *= image.get_size()
	bounds.size *= image.get_size()
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			if Geometry.point_is_inside_triangle(Vector2(x, y) / image.get_size(), uv_a, uv_b, uv_c):
				image.set_pixel(x, y, color)


static func get_triangle_bounds(a : Vector2, b : Vector2, c : Vector2) -> Rect2:
	var bounds := Rect2()
	bounds = bounds.expand(a)
	bounds = bounds.expand(b)
	bounds = bounds.expand(c)
	return bounds
