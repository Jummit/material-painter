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
export var maps : Dictionary setget set_maps
export var mask : Resource setget set_mask
export var name := "Untitled Layer"
export var opacities := {}
export var blend_modes := {}
export var visible := true

var parent
var dirty := true

const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const MaterialGenerationContext = preload("res://material_generation_context.gd")

func _init() -> void:
	resource_local_to_scene = true
	for map in Constants.TEXTURE_MAP_TYPES:
		opacities[map] = 1.0
		blend_modes[map] = "normal"


func set_maps(to):
	maps = to
	for map in maps.values():
		map.parent = self


func set_mask(to):
	mask = to
	if mask:
		mask.parent = self


func update(context : MaterialGenerationContext, force_all := false) -> void:
	if not dirty and not force_all:
		return
	for layer in get_layer_textures():
		var result = layer.update(context, force_all)
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
