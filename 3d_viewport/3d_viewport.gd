extends ViewportContainer

signal painted(layer)

const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")

onready var model : MeshInstance = $Viewport/Model
onready var layer_tree : Tree = $"../../../LayerTree/LayerTree"

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var selected_texture_layer : BitmapTextureLayer = layer_tree.get_selected_texture_layer()
		if selected_texture_layer:
			var camera : Camera = $Viewport.get_camera()
			var camera_world_position := camera.project_position(event.position, 0.0)
			var clicked_world_position := camera.project_position(event.position, 1000.0)
			
			var selected_face := _get_nearest_intersecting_face(camera_world_position, clicked_world_position, model.mesh)
			if selected_face != -1:
				paint_face(selected_texture_layer.image_data, selected_face, Color.white, model.mesh)
				emit_signal("painted", selected_texture_layer)


func _get_nearest_intersecting_face(start : Vector3, direction : Vector3, mesh : Mesh) -> int:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	
	var nearest_face := -1
	var nearest_face_pos := Vector3(INF, INF, INF)
	for face in mesh_tool.get_face_count():
		var triangle := Basis(
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 2)))
		var collision_point = Geometry.ray_intersects_triangle(
				start, direction, triangle.x, triangle.y, triangle.z)
		if collision_point and collision_point.distance_to(start) < nearest_face_pos.distance_to(start):
			nearest_face = face
			nearest_face_pos = collision_point
	return nearest_face


func paint_face(image : Image, face : int, color : Color, mesh : Mesh) -> void:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	var uv_a := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0))
	var uv_b := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1))
	var uv_c := mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))
	var bounds := get_triangle_bounds(uv_a, uv_b, uv_c)
	var size := image.get_size()
	bounds.position *= size
	bounds.size *= size
	# todo: use for loop
	for x in range(bounds.position.x, bounds.end.x):
		for y in range(bounds.position.y, bounds.end.y):
			if Geometry.point_is_inside_triangle(Vector2(x, y) / size, uv_a, uv_b, uv_c):
				image.set_pixel(x, y, color)


static func get_triangle_bounds(a : Vector2, b : Vector2, c : Vector2) -> Rect2:
	var bounds := Rect2()
	bounds = bounds.expand(a)
	bounds = bounds.expand(b)
	bounds = bounds.expand(c)
	return bounds
