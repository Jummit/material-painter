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
		var paint_texture := texture_layer_panel.editing_texture_layer as PaintTextureLayer
		if paint_texture:
			var selected_face := get_selected_face(get_local_mouse_position())
			if selected_face != -1:
				paint_texture.paint_face(selected_face, Color.white, model.mesh)
			(texture as ImageTexture).create_from_image(paint_texture.painted_image)


func get_selected_face(position : Vector2) -> int:
	for face in mesh_tool.get_face_count():
		if Geometry.point_is_inside_triangle(position / rect_size,
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex_uv(mesh_tool.get_face_vertex(face, 2))):
			return face
	return -1
