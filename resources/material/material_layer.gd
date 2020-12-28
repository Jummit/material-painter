extends Resource

"""
A single layer of a `LayerMaterial`

The `properties` `Dictionary` holds a `mask` that is used when blending the layers
and can hold a `LayerTexture` for each map (for example albedo, height, etc...).
"""

# warning-ignore-all:unused_class_variable
export var maps : Dictionary
export var mask : Resource
export var name := "Untitled Layer"
export var opacity := 1.0
export var blend_mode := "normal"
export var visible := true

var parent
var dirty := true

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")

func _init() -> void:
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer_texture in get_layer_textures():
		layer_texture.parent = self


func update(force_all := false) -> void:
	if not dirty and not force_all:
		return
	for layer in get_layer_textures():
		var result = layer.update(force_all)
		if result is GDScriptFunctionState:
			yield(result, "completed")
	dirty = false


func get_layer_material_in() -> Resource:
	if parent is MaterialFolder:
		return parent.get_layer_material_in()
	else:
		return parent


func get_layer_textures() -> Array:
	var layer_textures := maps.values()
	if mask:
		layer_textures.append(mask)
	return layer_textures


func mark_dirty(shader_dirty := false) -> void:
	dirty = true
	get_layer_material_in().mark_dirty(shader_dirty)
