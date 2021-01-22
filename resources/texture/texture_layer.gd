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

var parent
var type_name : String
var icon : Texture
var dirty := true
var icon_dirty := true

const Layer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").Layer
const LayerTexture = preload("res://resources/texture/layer_texture.gd")

func _init(_name : String):
	resource_local_to_scene = true
	type_name = _name
	name = _name


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
	icon_dirty = true
	get_layer_texture_in().mark_dirty(shader_dirty)


func update(force_all := false) -> void:
	if not dirty and not force_all:
		return
	var shader_layer = _get_as_shader_layer()
	if shader_layer is GDScriptFunctionState:
		shader_layer = yield(shader_layer, "completed")
	dirty = false


func update_icon() -> void:
	if not icon_dirty:
		return
	var shader_layer = _get_as_shader_layer()
	if shader_layer is GDScriptFunctionState:
		shader_layer = yield(shader_layer, "completed")
	icon = yield(LayerBlendViewportManager.blend(
			[shader_layer], Vector2(16, 16)), "completed")
	icon_dirty = false


func get_layer_texture_in() -> LayerTexture:
	if parent is LayerTexture:
		return parent
	else:
		# parent is a `TextureFolder`
		return parent.get_layer_texture_in()


func get_properties() -> Array:
	return []


func _get_as_shader_layer() -> Layer:
	return null
