extends "res://viewport/viewport.gd"

var original_mesh : Mesh

func get_painter() -> Painter:
	var painter := .get_painter()
	painter.paint_through = true
	return painter


func _on_Main_mesh_changed(to : Mesh) -> void:
	original_mesh = to
	set_mesh(uv_to_vertex_positions(to, 0))


func _on_Main_current_layer_material_changed(_to : Reference, id : int) -> void:
	._on_Main_current_layer_material_changed(_to, id)
	set_mesh(uv_to_vertex_positions(original_mesh, id))


static func uv_to_vertex_positions(mesh : Mesh, surface : int) -> Mesh:
	var data_tool := MeshDataTool.new()
	var new_mesh := Mesh.new()
	for surface_num in mesh.get_surface_count():
		data_tool.create_from_surface(mesh, surface)
		for vertex in data_tool.get_vertex_count():
			if surface_num == surface:
				var uv := data_tool.get_vertex_uv(vertex)
				data_tool.set_vertex(vertex, Vector3(uv.x, 1.0 - uv.y, 0))
			else:
				# Kinda hacky: move all vertices of the unused surfaces to 0,0,0.
				data_tool.set_vertex(vertex, Vector3.ZERO)
		data_tool.commit_to_surface(new_mesh)
	return new_mesh
