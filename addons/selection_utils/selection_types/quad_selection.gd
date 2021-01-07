extends "res://addons/selection_utils/selection_type.gd"

const MeshUtils = preload("res://addons/selection_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh) -> Mesh:
	var original_data_tool := MeshDataTool.new()
	original_data_tool.create_from_surface(mesh, 0)
	
	var joined_data := MeshUtils.join_duplicates(mesh)
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(joined_data.mesh, 0)
	
	var quads := MeshUtils.get_quads(mesh_tool)
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var color : Color
	for face1 in quads:
		var face2 : int = quads[face1]
		color = get_color()
		for face in [face1, face2]:
			for vertex_num in 3:
				var vertex := original_data_tool.get_face_vertex(face, vertex_num)
				surface_tool.add_uv(original_data_tool.get_vertex_uv(vertex))
				surface_tool.add_color(color)
				surface_tool.add_vertex(original_data_tool.get_vertex(vertex))
	
	return surface_tool.commit()
