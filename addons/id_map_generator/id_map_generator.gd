extends Viewport

"""
A `Viewport` that renders each part of the mesh with a different color
"""

onready var mesh_instance : MeshInstance = $MeshInstance

const MeshUtils = preload("res://addons/third_party/mesh_utils/mesh_utils.gd")

func generate_id_map(mesh : Mesh, result_size : Vector2,
		surface : int) -> ViewportTexture:
	var original_data_tool := MeshDataTool.new()
	original_data_tool.create_from_surface(mesh, 0)
	
	var data_tool := MeshDataTool.new()
	var joined_data := MeshUtils.join_duplicates(mesh, surface)
	data_tool.create_from_surface(joined_data.mesh, 0)
	
	var ids := []
	var checked := []
	for face in data_tool.get_face_count():
		if not face in checked:
			var connected := MeshUtils.get_connected_faces(data_tool, face)
			for connected_face in connected:
				checked.append(connected_face)
			ids.append(connected)
	
	for id_num in ids.size():
		for face in ids[id_num]:
			var color := Color().from_hsv(float(id_num) / float(ids.size()),
					1.0, 1.0)
			for vertex in 3:
				original_data_tool.set_vertex_color(
						original_data_tool.get_face_vertex(face, vertex), color)
	
	var new_mesh := Mesh.new()
	original_data_tool.commit_to_surface(new_mesh)
	size = result_size
	mesh_instance.mesh = new_mesh
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()
