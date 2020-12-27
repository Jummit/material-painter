extends Node

"""
Global utility used to blend textures from anywhere

Adds persistent `LayerBlendingViewport`s if `blend` is called with a given `id`.
This avoids having to make the resulting texture local by keeping the viewport.
"""

const TextureUtils = preload("res://utils/texture_utils.gd")
const LayerBlendingViewport = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd")
const LayerBlendingViewportScene = preload("res://addons/layer_blending_viewport/layer_blending_viewport.tscn")

func blend(layers : Array, result_size : Vector2, id := -1, update_shader := false) -> Texture:
	var layer_blend_viewport : LayerBlendingViewport
	if id != -1 and has_node(str(id)):
		layer_blend_viewport = get_node(str(id))
	else:
		layer_blend_viewport = LayerBlendingViewportScene.instance()
		layer_blend_viewport.name = str(randi() if id == -1 else id)
		add_child(layer_blend_viewport)
	var result : Texture = yield(layer_blend_viewport.blend(layers, result_size, update_shader), "completed")
	if id == -1:
		return TextureUtils.viewport_to_image(result)
	return result
