extends Resource

"""
A layer of a `LayerMaterial`

`mask` is used when blending the layers.
`maps` is a dictionary which can hold a `LayerTexture` for each map, for example
albedo, metallic or height.

`MaterialLayer`s can be hidden, which excludes them from the result of the
`LayerMaterial`.

It is marked dirty when the child `LayerTexture`s change, which will mark the
parent `LayerMaterial` dirty.
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


func get_map_result(map : String) -> Texture:
	if not map in maps:
		return null
	return maps[map].result


