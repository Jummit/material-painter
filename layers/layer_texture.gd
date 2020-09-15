extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a result which is updated when settings of the layers change.
"""

export var layers : Array
# warning-ignore:unused_class_variable
export var name := "Untitled Texture"

var result : Texture

func _init() -> void:
	resource_local_to_scene = true


func generate_result(result_size : Vector2, keep_viewport := true) -> void:
	var blending_layers := []
	for layer in layers:
		blending_layers.append(layer._get_as_shader_layer())
	result = yield(LayerBlendViewportManager.blend(blending_layers, result_size, get_instance_id(), keep_viewport), "completed")
