extends Reference

"""
A layer of a `LayerTexture`

For making the layer editable, `get_properties` is used
to retrieve a list of `Properties` for the `LayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
var name : String
var visible : bool

var parent : Reference
var icon : Texture
var dirty := true
var shader_dirty := true
var icon_dirty := true

const Layer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").Layer
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")

func _init(data := {}) -> void:
	name = data.get("name", "")
	if not name:
		name = get_name()
	visible = data.get("visible", true)


func serialize() -> Dictionary:
	var data := {
		name = name,
		visible = visible,
		type = get_type(),
	}
	return data


func mark_dirty(shader_too := false) -> void:
	dirty = true
	icon_dirty = true
	shader_dirty = shader_dirty or shader_too
# warning-ignore:unsafe_method_access
	get_layer_texture_in().mark_dirty(shader_too)


func get_type() -> String:
	return ""


func get_name() -> String:
	return get_type().capitalize()


func update(context : MaterialGenerationContext, force_all := false) -> void:
	if not dirty and not force_all:
		return
	var shader_layer = _get_as_shader_layer(context)
	if shader_layer is GDScriptFunctionState:
		shader_layer = yield(shader_layer, "completed")
	dirty = false


func update_icon(context : MaterialGenerationContext) -> void:
	if not icon_dirty:
		return
	var shader_layer = _get_as_shader_layer(context)
	if shader_layer is GDScriptFunctionState:
		shader_layer = yield(shader_layer, "completed")
	icon = yield(context.blending_viewport_manager.blend([shader_layer],
			context.icon_size), "completed")
	icon_dirty = false


func get_layer_material_in() -> Reference:
# warning-ignore:unsafe_property_access
	return get_layer_texture_in().parent.get_layer_material_in()


func get_layer_texture_in() -> Reference:
	if "get_layer_texture_in" in parent:
# warning-ignore:unsafe_method_access
		return parent.get_layer_texture_in()
	else:
		return parent


func get_properties() -> Array:
	return []


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	return null


func duplicate() -> Object:
	return get_script().new(serialize())
