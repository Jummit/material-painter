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

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")

func _init() -> void:
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer_texture in get_layer_textures():
		layer_texture.parent = self


func get_layer_material_in() -> LayerMaterial:
	if parent is LayerMaterial:
		return parent
	else:
		return parent.get_layer_texture_in()


func update() -> void:
	for layer_texture in get_layer_textures():
		yield(layer_texture.update(), "completed")


func get_layer_textures() -> Array:
	var layer_textures := maps.values()
	if mask:
		layer_textures.append(mask)
	return layer_textures
