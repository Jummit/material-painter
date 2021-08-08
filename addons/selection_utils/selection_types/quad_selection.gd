extends "../selection_type.gd"

"""
Selection that splits geometry into single quads (two triangles each)
"""

const MeshUtils = preload("res://addons/third_party/mesh_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh, surface : int) -> Mesh:
	var data_tool := MeshDataTool.new()
	data_tool.create_from_surface(mesh, surface)
	
	var joined_data := MeshUtils.join_duplicates(mesh, surface)
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(joined_data.mesh, surface)
	
	var quads := MeshUtils.get_quads(mesh_tool)
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var color : Color
	for face1 in quads:
		var face2 : int = quads[face1]
		color = get_color()
		for face in [face1, face2]:
			for vertex_num in 3:
				var vertex := data_tool.get_face_vertex(face, vertex_num)
				surface_tool.add_uv(data_tool.get_vertex_uv(vertex))
				surface_tool.add_color(color)
				surface_tool.add_vertex(data_tool.get_vertex(vertex))
	
	return surface_tool.commit()
