extends TextureRect

"""
A panel for painting onto a texture using the UV of a model
"""

signal painted(layer)

const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")
const MeshUtils = preload("res://utils/mesh_utils.gd")

var mesh_tool := MeshDataTool.new()

onready var model : MeshInstance = $"../3DViewport/ViewportContainer/Viewport/Model"
onready var layer_tree : Tree = $"../../../LayerPanelContainer/LayerTree"

func _ready() -> void:
	mesh_tool.create_from_surface(model.mesh, 0)


func _draw() -> void:
	draw_faces_as_lines()


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if layer_tree.get_selected():
			var layer_texture := layer_tree.get_selected_texture_layer() as BitmapTextureLayer
			if layer_texture:
				var selected_face := _get_selected_face(get_local_mouse_position())
				if selected_face != -1:
					MeshUtils.paint_face(layer_texture.image_data, selected_face, Color.white, model.mesh)
					texture.create_from_image(layer_texture.image_data)
					emit_signal("painted", layer_texture)


func _get_selected_face(position : Vector2) -> int:
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
