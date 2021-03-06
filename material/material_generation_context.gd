extends Reference

# warning-ignore-all:unused_class_variable
var mesh : Mesh
var result_size := Vector2(64, 64)
var icon_size := Vector2(32, 32)
#var icon_size := Vector2(128, 128)
var blending_viewport_manager : LayerBlendViewportManager
var triplanar_generator : TriplanarTextureGenerator
var normal_map_generator : NormalMapGenerationViewport

const LayerBlendViewportManager = preload("res://addons/layer_blending_viewport/layer_blend_viewport_manager.gd")
const TriplanarTextureGenerator = preload("res://addons/triplanar_texture_generator/triplanar_texture_generator.gd")
const NormalMapGenerationViewport = preload("res://addons/normal_map_generation_viewport/normal_map_generation_viewport.gd")

func _init(_blending_viewport_manager : LayerBlendViewportManager,
		_normal_map_generator : Viewport,
		_triplanar_generator : TriplanarTextureGenerator) -> void:
	blending_viewport_manager = _blending_viewport_manager
	normal_map_generator = _normal_map_generator
	triplanar_generator = _triplanar_generator
