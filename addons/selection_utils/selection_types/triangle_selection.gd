extends "../selection_type.gd"

const MeshUtils = preload("res://addons/third_party/mesh_utils/mesh_utils.gd")

static func prepare_mesh(mesh : Mesh, surface : int) -> Mesh:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, surface)
	
	var vertices : PoolVector3Array = []
	var uvs : PoolVector2Array = []
	var colors : PoolColorArray = []
	
	for face in mesh_tool.get_face_count():
		var color := get_color()
		for v in 3:
			var vertex := mesh_tool.get_face_vertex(face, v)
			vertices.append(mesh_tool.get_vertex(vertex))
			uvs.append(mesh_tool.get_vertex_uv(vertex))
			colors.append(color)
	
	var array_mesh := ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return array_mesh
