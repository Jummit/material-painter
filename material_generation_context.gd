extends Reference

var mesh : Mesh
var result_size : Vector2
# warning-ignore:unused_class_variable
var icon_size : Vector2
var blending_viewport_manager : LayerBlendViewportManager
var triplanar_generator : TriplanarTextureGenerator
var normal_map_generator : Viewport

const LayerBlendViewportManager = preload("res://addons/layer_blending_viewport/layer_blend_viewport_manager.gd")
const TriplanarTextureGenerator = preload("res://addons/triplanar_texture_generator/triplanar_texture_generator.gd")

func _init(_blending_viewport_manager : LayerBlendViewportManager,
		_normal_map_generator : Viewport,
		_triplanar_generator : TriplanarTextureGenerator) -> void:
	blending_viewport_manager = _blending_viewport_manager
	normal_map_generator = _normal_map_generator
	triplanar_generator = _triplanar_generator
