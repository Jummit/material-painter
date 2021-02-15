extends "res://addons/selection_utils/selection_type.gd"

const MeshUtils = preload("res://addons/mesh_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh, surface : int) -> Mesh:
	var original_data_tool := MeshDataTool.new()
	original_data_tool.create_from_surface(mesh, 0)
	
	var joined_data := MeshUtils.join_duplicates(mesh, surface)
	
	var steep_list := MeshUtils.get_steep_edges(joined_data.mesh)
	var steep := {}
	for edge in steep_list:
		steep[edge] = true
	
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(joined_data.mesh, 0)
	var ids := MeshUtils.get_connected_geometry(data_tool, steep)
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for faces in ids:
		var color := get_color()
		for face in faces:
			for vertex_num in 3:
				var vertex := original_data_tool.get_face_vertex(face, vertex_num)
				surface_tool.add_uv(original_data_tool.get_vertex_uv(vertex))
				surface_tool.add_color(color)
				surface_tool.add_vertex(original_data_tool.get_vertex(vertex))
	
	return surface_tool.commit()
