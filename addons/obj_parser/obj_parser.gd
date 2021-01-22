"""
A utility to parse .obj object files

Loads the material if the path to the .mtl file is specified.
"""

const ObjParserInteractive = preload("obj_parser_interactive.gd")
const MtlParser = preload("mtl_parser.gd")

static func parse_obj(path : String) -> Mesh:
	var file := File.new()
	var error := file.open(path, File.READ)
	if error != OK:
		return null
	
	var mesh := ArrayMesh.new()
	mesh.resource_path = path
	mesh.resource_name = path.get_file().trim_suffix(".obj")
	
	var vertices := PoolVector3Array()
	var normals := PoolVector3Array()
	var uvs := PoolVector2Array()
	var materials := {}
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var surface_tool_has_vertices := false
	
	var current_material_library : String
	var current_material : String
	var current_group : String
	
	while true:
		var line := file.get_line().strip_edges()
		var split := line.split(" ", false)
		var element := split[0] if split.size() else ""
		match element:
			"v":
				vertices.append(Vector3(float(split[1]), float(split[2]),
						float(split[3])))
			"vn":
				normals.append(Vector3(float(split[1]), float(split[2]),
						float(split[3])))
			"vt":
				uvs.append(Vector2(float(split[1]), 1.0 - float(split[2])))
			"f":
				surface_tool_has_vertices = true
				var face := []
				face.resize(3)
				face[0] = split[1].split("/")
				face[1] = split[2].split("/")
				for i in range(2, split.size() - 1):
					face[2] = split[i + 1].split("/")
					for j in 3:
						var index : int = j
						if index < 2:
							index = 1 ^ index
						if face[index].size() == 3:
							var normal := int(face[index][2]) - 1
							if normal < 0:
								normal += normals.size() + 1
							surface_tool.add_normal(normals[normal])
						
						if face[index].size() >= 2 and face[index][1]:
							var uv := int(face[index][1]) - 1
							if uv < 0:
								uv += uvs.size() + 1
							surface_tool.add_uv(uvs[uv])
						
						var vertex := int(face[index][0]) - 1
						if vertex < 0:
							vertex += vertices.size() + 1
						surface_tool.add_vertex(vertices[vertex])
					face[1] = face[2]
			"s":
				surface_tool.add_smooth_group(not split[1] == "off")
			"mtllib":
				current_material_library = split[1]
				if not current_material_library in materials:
					var library := MtlParser.parse_material_library(
							path.get_base_dir().plus_file(
							current_material_library))
					if library:
						materials[current_material_library] = library
			"usemtl":
				current_material = split[1]
			"g":
				current_group = split[1]
		if file.eof_reached() or ((element == "usemtl" or element == "o")\
				and surface_tool_has_vertices):
			if normals.size():
				surface_tool.generate_normals()
			if uvs.size():
				surface_tool.generate_tangents()
			surface_tool.index()
			if current_material_library in materials\
					and current_material in materials[current_material_library]:
				surface_tool.set_material(
						materials[current_material_library][current_material])
			mesh = surface_tool.commit(mesh)
			if current_material:
				mesh.surface_set_name(mesh.get_surface_count() - 1,
						current_material.get_basename())
			elif current_group:
				mesh.surface_set_name(mesh.get_surface_count() - 1,
						current_group)
			surface_tool.clear()
			surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface_tool_has_vertices = false
		if file.eof_reached():
			break
	return mesh


static func parse_obj_interactive(path : String) -> ObjParserInteractive:
	return ObjParserInteractive.new(path)
