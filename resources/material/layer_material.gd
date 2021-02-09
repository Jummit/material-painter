extends Resource

"""
A material whose texture maps are generated by blending several `MaterialLayers`

`layers` contains the `MaterialLayers`, each of which can have multiple channels
enabled. When generating the results, all `LayerTexture`s of each map are blended
together and stored in the `results` `Dictionary`. It stores the blended
`Texture`s with the map names as keys.

To make it possible to use Viewports inside of sub-resources of MaterialLayers,
this and every `Resource` class that is used inside of it has to be local to scene.

It is marked dirty when a child `MaterialLayer` is marked dirty, and will then
update the result when `update` is called.

If `shader_dirty` is true, the shader needs to be recompiled. This is not
necessary if only parameters changed.
"""

export var layers : Array

var result_size := Vector2(1024, 1024)
# warning-ignore:unused_class_variable
var mesh : Mesh

var results : Dictionary
var dirty := true
var shader_dirty := false
var busy := false

const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const TextureFolder = preload("res://resources/texture/texture_folder.gd")
const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")

func _init() -> void:
	resource_local_to_scene = true
	for layer in layers:
		layer.parent = self


func add_layer(layer, onto, position := -1, update := true) -> void:
	layer.parent = onto
	if position == -1:
		onto.layers.append(layer)
	else:
		onto.layers.insert(position, layer)
	layer.mark_dirty(true)
	if update:
		update()


func delete_layer(layer, update := true) -> void:
	layer.parent.layers.erase(layer)
	layer.parent.mark_dirty(true)
	if update:
		update()


func mark_dirty(shader_too := false) -> void:
	dirty = true
	shader_dirty = shader_too


func update(force_all := false) -> void:
	if busy or not dirty:
		return
	
	busy = true
	
	for layer in layers:
		var result = layer.update(force_all)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
	
	var generated_height := false
	for map in Constants.TEXTURE_MAP_TYPES:
		var blending_layers := []
		for layer in layers:
			var map_result : Texture = layer.get_map_result(map)
			if not map_result or not layer.visible:
				continue
			
			var blending_layer : BlendingLayer
			if layer.mask:
				blending_layer = BlendingLayer.new(
					"texture({layer_result}, uv)",
					"normal", 1.0, layer.mask.result)
			else:
				blending_layer = BlendingLayer.new("texture({layer_result}, uv)")
			blending_layer.uniform_types.append("sampler2D")
			blending_layer.uniform_names.append("layer_result")
			blending_layer.uniform_values.append(map_result)
			blending_layers.append(blending_layer)
		
		if blending_layers.empty():
			if map != "normal" or not generated_height:
				results.erase(map)
			continue
		
		var result : Texture = yield(LayerBlendViewportManager.blend(
				blending_layers, result_size, get_instance_id() + map.hash(),
				shader_dirty), "completed")
		
		if map == "height":
			result = yield(NormalMapGenerationViewport.get_normal_map(result),
					"completed")
			map = "normal"
			generated_height = true
		results[map] = result
	dirty = false
	shader_dirty = false
	busy = false
	emit_signal("changed")


func get_material(existing : SpatialMaterial = null) -> SpatialMaterial:
	var material_maps = Constants.TEXTURE_MAP_TYPES.duplicate()
	material_maps.erase("height")
	material_maps.append("normal")
	
	var material : SpatialMaterial = existing
	if not existing:
		material = preload("res://misc/material.tres").duplicate()
	
	for map in material_maps:
		if map in results.keys():
			material.set(map + "_enabled", true)
			material.set(map + "_texture", results[map])
		else:
			material.set(map + "_enabled", false)
			material.set(map + "_texture", null)
		
		if map == "metallic":
			material.set("metallic", int(map in results.keys()))
	
	return material


func get_flat_layers(layer_array : Array = layers, add_hidden := true) -> Array:
	var flat_layers := []
	for layer in layer_array:
		if (not add_hidden) and not layer.visible:
			continue
		if layer is MaterialFolder:
			flat_layers += get_flat_layers(layer.layers, add_hidden)
		else:
			flat_layers.append(layer)
	return flat_layers


func replace_paths(path : String, with : String) -> void:
	for texture_layer in get_texture_layers():
		if texture_layer is FileTextureLayer:
			texture_layer.path = texture_layer.path.replace(path, with)


func get_texture_layers() -> Array:
	var texture_layers := []
	for material_layer in get_flat_layers():
		for layer_texture in material_layer.get_layer_textures():
			for texture_layer in layer_texture.get_flat_layers():
				texture_layers.append(texture_layer)
	return texture_layers
