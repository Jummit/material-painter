extends Reference

"""
A layer of a `LayerTexture`

For making the layer editable, `get_properties` is used
to retrieve a list of `Properties` for the `LayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
var name : String
var visible : bool

var parent
var icon : Texture
var dirty := true
var icon_dirty := true

const Layer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").Layer
const LayerTexture = preload("res://data/texture/layer_texture.gd")
const MaterialGenerationContext = preload("res://material_generation_context.gd")

func _init(data := {}) -> void:
	name = data.get("name", "")
	visible = data.get("visible", true)


func serialize() -> Dictionary:
	var data := {
		name = name,
		visible = visible,
	}
	return data


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
	icon_dirty = true
	get_layer_texture_in().mark_dirty(shader_dirty)


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


func get_layer_material_in() -> Resource:
	return get_layer_texture_in().parent.get_layer_material_in()


func get_layer_texture_in() -> LayerTexture:
	if parent is LayerTexture:
		return parent
	else:
		# Parent is a `TextureFolder`.
		return parent.get_layer_texture_in()


func get_properties() -> Array:
	return []


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	return null
