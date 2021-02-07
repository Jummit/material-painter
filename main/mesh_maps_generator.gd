extends Node

"""
Utility for managing generation of different mesh maps
"""

const TextureUtils = preload("res://utils/texture_utils.gd")

const BAKE_FUNCTIONS := {
	curvature = "bake_curvature_map",
	id = "generate_id_map",
	world_normal = "bake_world_normal",
	world_position = "generate_world_map",
}

func generate_mesh_map(map : String, mesh : Mesh,
		result_size : Vector2) -> ImageTexture:
	var result : Texture = yield(get_node(map).call(BAKE_FUNCTIONS[map], mesh,
				result_size), "completed")
	if result is ViewportTexture:
		return TextureUtils.viewport_to_image(result)
	return result


func generate_mesh_maps(mesh : Mesh, result_size : Vector2) -> Dictionary:
	var maps := {}
	for map in BAKE_FUNCTIONS:
		maps[map] = yield(generate_mesh_map(map, mesh, result_size), "completed")
	return maps
