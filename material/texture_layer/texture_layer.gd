extends Reference

"""
A layer of a `LayerTexture`

For making the layer editable, `get_properties` is used
to retrieve a list of `Properties` for the `LayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
var name : String
var visible : bool
var enabled_maps : Dictionary
var opacities : Dictionary
var blend_modes : Dictionary
var settings := {}

var parent : Reference
var dirty := true
var shader_dirty := true
var icon_dirty := true

var icon : Texture

const Layer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").Layer
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")

func _init(data := {}) -> void:
	name = data.get("name", "")
	settings = data.get("settings", {})
	if not name:
		name = get_name()
	visible = data.get("visible", true)


func serialize() -> Dictionary:
	var data := {
		name = name,
		visible = visible,
		settings = settings,
		type = get_type(),
	}
	return data


func mark_dirty(shader_too := false) -> void:
	dirty = true
	icon_dirty = true
# warning-ignore:unsafe_method_access
	parent.mark_dirty(shader_too)
	shader_dirty = shader_dirty or shader_too


func get_type() -> String:
	return ""


func get_icon(map : String, context : MaterialGenerationContext) -> Texture:
	if not icon or icon_dirty:
		# Layer could be null.
		var layer := get_blending_layer(context, map)
		if not layer:
			return null
		context.blending_viewport_manager.blend([layer], context.icon_size)
		icon_dirty = false
	return icon


func get_name() -> String:
	return get_type().capitalize()


func get_properties() -> Array:
	return []


func get_blending_layer(_context : MaterialGenerationContext,
		_map : String) -> Layer:
	return null


func duplicate() -> Object:
	return get_script().new(serialize())
