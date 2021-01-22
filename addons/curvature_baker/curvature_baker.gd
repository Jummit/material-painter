extends Node

"""
A utility that bakes grayscale curvature maps from a mesh
"""

onready var line_renderer : Viewport = $LineRenderer

const CurvatureUtils := preload("curvature_utils.gd")
const MeshUtils := preload("mesh_utils.gd")

func bake_curvature_map(mesh : Mesh, result_size : Vector2,
		surface := 0) -> ImageTexture:
	var mesh_tool := MeshDataTool.new()
	var join_data := MeshUtils.join_duplicates(mesh)
	mesh_tool.create_from_surface(join_data.mesh, surface)
	var edge_curvatures = CurvatureUtils.get_edge_curvatures(mesh_tool)
	var lines : PoolVector2Array = []
	var colors : PoolColorArray = []
	
	var old_mesh_tool := MeshDataTool.new()
	old_mesh_tool.create_from_surface(mesh, surface)
	for edge in mesh_tool.get_edge_count():
		var curvature : float = edge_curvatures[edge]
		if curvature == 0:
			continue
		var a := mesh_tool.get_edge_vertex(edge, 0)
		var b := mesh_tool.get_edge_vertex(edge, 1)
		for a_id in join_data.original_ids[a]:
			for a_edge in old_mesh_tool.get_vertex_edges(a_id):
				var egde_verts := [
					old_mesh_tool.get_edge_vertex(a_edge, 0),
					old_mesh_tool.get_edge_vertex(a_edge, 1),
				]
				for other_id in join_data.original_ids[b]:
					if other_id in egde_verts:
						lines.append(old_mesh_tool.get_vertex_uv(a_id))
						lines.append(old_mesh_tool.get_vertex_uv(other_id))
						colors.append(_grayscale((curvature + 1) / 2.0))
	
	var result = line_renderer.render_lines(lines, colors, result_size,
			MeshUtils.get_texel_density(mesh) / 500.0, _grayscale(.5))
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result


func _grayscale(value : float) -> Color:
	return Color().from_hsv(0, 0, value)
