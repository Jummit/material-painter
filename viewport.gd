extends Viewport

onready var main : Control = $"../../../../../../.."
onready var model : MeshInstance = $Model
onready var texture_layer_panel : VBoxContainer = $"../../../../TextureLayerPanel"

const Debug3D = preload("res://addons/debug_3d/debug_3d.gd")
const PaintTextureLayer = preload("res://texture_layers/types/paint_texture_layer.gd")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if texture_layer_panel.editing_texture_layer is PaintTextureLayer:
			var camera := get_viewport().get_camera()
			var camera_world_position := camera.project_position(get_mouse_position(), 0.0)
			var clicked_world_position := camera.project_position(get_mouse_position(), 1000.0)
			
			Debug3D.line(camera_world_position, clicked_world_position, Color.red, 3.0, self)
			
			var selected_face := get_nearest_intersecting_face(camera_world_position, clicked_world_position, model.mesh)
			if selected_face != -1:
				texture_layer_panel.editing_texture_layer.paint_face(selected_face, Color.white, model.mesh)
				texture_layer_panel.editing_texture_layer.generate_texture()
				main.update_layer_texture(texture_layer_panel.editing_layer_texture)


func get_nearest_intersecting_face(start : Vector3, direction : Vector3, mesh : Mesh) -> int:
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


static func get_triangle_center(triangle : Basis) -> Vector3:
	return (triangle.x + triangle.y + triangle.z) / 3.0
