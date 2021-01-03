extends TextureRect

"""
A panel for painting onto a texture using the UV of a model
"""

var _mesh_tool := MeshDataTool.new()

const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")

func _ready():
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")


func _draw() -> void:
	draw_faces_as_lines()


func _on_Globals_mesh_changed(mesh : Mesh) -> void:
	_mesh_tool.create_from_surface(mesh, 0)
	update()


func draw_faces_as_lines(color := Color.white, line_width := 2.0) -> void:
	for face in _mesh_tool.get_face_count():
		var points : PoolVector2Array = [
				_mesh_tool.get_vertex_uv(_mesh_tool.get_face_vertex(face, 0)),
				_mesh_tool.get_vertex_uv(_mesh_tool.get_face_vertex(face, 1)),
				_mesh_tool.get_vertex_uv(_mesh_tool.get_face_vertex(face, 2))]
		points.append(points[0])
		points = Transform2D.IDENTITY.scaled(rect_size).xform(points)
		draw_multiline(points, color, line_width)
