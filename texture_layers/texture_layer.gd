extends Resource

"""
A layer of a `LayerTexture`

By default the settings include the blend_mode
and the opacity to configure the strength when blending.
The `properties` `Dictionary` holds the settings of the layer.

For making the layer editable, `get_properties` is used
to retrieve a list of `Properties` for the `TextureLayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
export var name : String
export var properties : Dictionary
export var visible := true
var type_name : String

var result : Texture

const Properties = preload("res://addons/property_panel/properties.gd")
const Layer = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd").Layer

func _init(_type_name : String):
	type_name = _type_name
	properties = {
		opacity = 1.0,
		blend_mode = "normal"
	}


func get_properties() -> Array:
	return [
		Properties.FloatProperty.new("opacity", 0.0, 1.0),
		Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES)]


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.blend_mode = properties.blend_mode
	layer.opacity = properties.opacity
	return layer
