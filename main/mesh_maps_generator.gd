"""
Utility for managing generation of different mesh maps
"""

const TextureUtils = preload("res://utils/texture_utils.gd")

class MeshMapGenerator:
	var name : String
	
	func _init(_name : String) -> void:
		name = _name
	
	func _generate_map(_mesh : Mesh, _result_size : Vector2) -> Texture:
		return null

class IDMeshMapGenerator extends MeshMapGenerator:
	func _init().("id_map") -> void:
		pass
	
	func _generate_map(mesh : Mesh, result_size : Vector2) -> Texture:
		return TextureUtils.viewport_to_image(
				yield(IDMapGenerator.generate_id_map(mesh, result_size),
				"completed"))

class WorldPositionMeshMapGenerator extends MeshMapGenerator:
	func _init().("world_position_map") -> void:
		pass
	
	func _generate_map(mesh : Mesh, result_size : Vector2) -> Texture:
		return TextureUtils.viewport_to_image(
				yield(WorldMapGenerator.generate_world_map(mesh, result_size),
				"completed"))

class CurvatureMapGenerator extends MeshMapGenerator:
	func _init().("curvature_map") -> void:
		pass
	
	func _generate_map(mesh : Mesh, result_size : Vector2) -> Texture:
		return yield(CurvatureBaker.bake_curvature_map(mesh, result_size,
				0.003), "completed")

var MESH_MAP_GENERATORS := [
	IDMeshMapGenerator.new(),
	CurvatureMapGenerator.new(),
	WorldPositionMeshMapGenerator.new(),
]

func generate_mesh_maps(mesh : Mesh, result_size : Vector2) -> Dictionary:
	var maps := {}
	for generator in MESH_MAP_GENERATORS:
		maps[generator.name] = yield(generator._generate_map(mesh, result_size),
				"completed")
	return maps
