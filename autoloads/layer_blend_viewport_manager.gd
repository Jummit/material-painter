extends Node

"""

"""

var one_time_viewport := LayerBlendingViewportScene.instance()

const TextureUtils = preload("res://utils/texture_utils.gd")
const LayerBlendingViewport = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd")
const LayerBlendingViewportScene = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.tscn")

func _ready() -> void:
	add_child(one_time_viewport)


func blend(layers : Array, result_size : Vector2, id := -1) -> Texture:
	var layer_blend_viewport : LayerBlendingViewport
	if id != -1:
		if has_node(str(id)):
			layer_blend_viewport = get_node(str(id))
		else:
			layer_blend_viewport = LayerBlendingViewportScene.instance()
			layer_blend_viewport.name = str(id)
			add_child(layer_blend_viewport)
	else:
		layer_blend_viewport = one_time_viewport
	var result : Texture = yield(layer_blend_viewport.blend(layers, result_size), "completed")
	if id == -1:
		result = TextureUtils.viewport_to_image(result)
	return result
