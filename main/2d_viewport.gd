extends TextureRect

onready var model : MeshInstance = $"../3DViewport/Viewport/Model"
onready var main : Control = $"../../../../../.."

const PaintTextureLayer = preload("res://texture_layers/types/paint_texture_layer.gd")

signal painted

var mesh_tool := MeshDataTool.new()

func _ready() -> void:
	mesh_tool.create_from_surface(model.mesh, 0)


func _draw() -> void:
	draw_faces_as_lines()


func _gui_input(event : InputEvent) -> void:
	# todo: update the texture not only when it is edited in 2d
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var paint_texture := main.editing_texture_layer as PaintTextureLayer
		if paint_texture:
			var selected_face := get_selected_face(get_local_mouse_position())
			if selected_face != -1:
				paint_texture.paint_face(selected_face, Color.white, model.mesh)
				texture.create_from_image(paint_texture.painted_image)
				emit_signal("painted")


func get_selected_face(position : Vector2) -> int:
	for face in mesh_tool.get_face_count():
		if Geometry.point_is_inside_triangle(position / rect_size,
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))):
			return face
	return -1


func draw_faces_as_lines(color := Color.yellow, line_width := 2.0) -> void:
	for face in mesh_tool.get_face_count():
		var points : PoolVector2Array = [
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))]
		points.append(points[0])
		points = Transform2D.IDENTITY.scaled(rect_size).xform(points)
		draw_multiline(points, color, line_width)
