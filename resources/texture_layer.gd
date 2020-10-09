extends Resource

"""
A layer of a `LayerTexture`

By default the settings include the blend_mode
and the opacity to configure the strength when blending.

For making the layer editable, `get_properties` is used
to retrieve a list of `Properties` for the `LayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
export var name : String
export var visible := true
export var opacity := 1.0
export var blend_mode := "normal"

var type_name : String

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(_type_name : String):
	resource_local_to_scene = true
	type_name = _type_name


func get_properties() -> Array:
	return [
			Properties.FloatProperty.new("opacity", 0.0, 1.0),
			Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES),
			]


func generate_result(result_size : Vector2, keep_viewport := false) -> Texture:
	return yield(LayerBlendViewportManager.blend(
			[_get_as_shader_layer()], result_size,
			get_instance_id() if keep_viewport else -1), "completed")


func _get_as_shader_layer() -> BlendingLayer:
	var layer := BlendingLayer.new()
	layer.blend_mode = blend_mode
	layer.opacity = opacity
	return layer
