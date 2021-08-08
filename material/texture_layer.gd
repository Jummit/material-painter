extends Reference

"""
A layer of a `TextureLayerStack`

For making the layer editable, `get_properties` is used to retrieve a list of
`Properties` for the `LayerPropertyPanel`.
"""

# warning-ignore-all:unused_class_variable
var name : String
var visible : bool
var enabled_maps : Dictionary setget set_enabled_maps
var opacities : Dictionary
var blend_modes : Dictionary
var settings := {}

var parent : Reference
var dirty := true
var shader_dirty := true
var icons_dirty := true

var icons : Dictionary

const Layer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").Layer
const MaterialGenerationContext = preload("material_generation_context.gd")

func _init(data := {}) -> void:
	name = data.get("name", "")
	settings = data.get("settings", {})
	if not name:
		name = get_name()
	visible = data.get("visible", true)


func set_enabled_maps(to):
	enabled_maps = to


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
	icons_dirty = true
# warning-ignore:unsafe_method_access
	parent.mark_dirty(shader_too)
	shader_dirty = shader_dirty or shader_too


func get_type() -> String:
	return ""


func get_icon(map : String, context : MaterialGenerationContext) -> Texture:
	if not map in icons or icons_dirty:
		# Layer could be null.
		var layer := get_blending_layer(context, map)
		if not layer:
			return null
		var result = context.blending_viewport_manager.blend([layer],
				context.icon_size)
		while result is GDScriptFunctionState:
			result = yield(result, "completed")
		icons[map] = result
		icons_dirty = false
	return icons[map]


func get_name() -> String:
	return get_type().capitalize()


func get_properties() -> Array:
	return []


func set_property(property : String, value) -> void:
	settings[property] = value


func _get(property : String):
	if property in settings:
		return settings.get(property)


func get_blending_layer(_context : MaterialGenerationContext,
		_map : String) -> Layer:
	return null


func duplicate() -> Object:
	return get_script().new(serialize().duplicate(true))
