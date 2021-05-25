extends Reference

"""
A material whose texture maps are generated by blending several `MaterialLayers`

`layers` contains the `MaterialLayers`, each of which can have multiple channels
enabled. When generating the results, all `LayerTexture`s of each map are blended
together and stored in the `results` `Dictionary`. It stores the blended
`Texture`s with the map names as keys.

It is marked dirty when a child `MaterialLayer` is marked dirty, and will then
update the result when `update` is called.

If `shader_dirty` is true, the shader needs to be recompiled. This is not
necessary if only parameters changed.
"""

signal results_changed

var layers : Array setget set_layers

var context : MaterialGenerationContext
var results : Dictionary
var dirty := true
var shader_dirty := false
var busy := false

const MaterialLayer = preload("material_layer.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const LayerTexture = preload("../texture/layer_texture.gd")
const TextureLayer = preload("../texture/texture_layer.gd")
const FileTextureLayer = preload("../texture/file_texture_layer.gd")
const MaterialGenerationContext = preload("res://material_generation_context.gd")

func _init(data := []) -> void:
	for layer in data:
		add_layer(MaterialLayer.new(layer), self, -1, false)


func serialize() -> Array:
	var serialized_layers := []
	for layer in layers:
		serialized_layers.append(layer.serialize())
	return serialized_layers


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
	if shader_too:
		shader_dirty = true


func update(force_all := false) -> void:
	if busy or not dirty:
		return
	
	busy = true
	
	for layer in layers:
		var result = layer.update(context, force_all)
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
			var mask
			if layer.mask:
				mask = layer.mask.result
			blending_layer = BlendingLayer.new(
				"texture({layer_result}, uv)",
				layer.get_blend_mode(map), layer.get_opacity(map), mask)
			blending_layer.uniform_types.append("sampler2D")
			blending_layer.uniform_names.append("layer_result")
			blending_layer.uniform_values.append(map_result)
			blending_layers.append(blending_layer)
		
		if blending_layers.empty():
			if map != "normal" or not generated_height:
				results.erase(map)
			continue
		var result : Texture = yield(context.blending_viewport_manager.blend(
				blending_layers, context.result_size,
				get_instance_id() + map.hash(), shader_dirty), "completed")
		
		if map == "height":
			result = yield(context.normal_map_generator.get_normal_map(result),
					"completed")
			map = "normal"
			generated_height = true
		results[map] = result
	dirty = false
	shader_dirty = false
	busy = false
	emit_signal("results_changed")


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


func set_layers(to):
	layers = to
	for layer in layers:
		layer.parent = self


func duplicate() -> Object:
	return get_script().new(serialize())
