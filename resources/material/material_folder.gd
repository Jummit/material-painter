extends Resource

"""
A folder layer containing `MaterialLayer`s used in a `LayerMaterial` for
organization and optimization
"""

# warning-ignore-all:unused_class_variable
export var name := "Untitled Folder"
export var visible := true
export var layers : Array
export var mask : Resource

var results : Dictionary
var parent
var dirty := false
var shader_dirty := false

const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init() -> void:
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer in layers:
		layer.parent = self


func get_layer_material_in() -> Resource:
	# hacky workaround to avoid cycling references
	if parent.has_method("get_layer_material_in"):
		return parent.get_layer_material_in()
	else:
		return parent


func mark_dirty(shader_too := false) -> void:
	dirty = true
	shader_dirty = shader_too
	parent.mark_dirty(shader_dirty)


func update(force_all := false) -> void:
	if not dirty and not force_all:
		return
	
	for layer in layers:
		var result = layer.update(force_all)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
	
	if mask:
		var result = mask.update(force_all)
		if result is GDScriptFunctionState:
			yield(result, "completed")
	
	for map in Globals.TEXTURE_MAP_TYPES:
		var blending_layers := []
		for layer in layers:
			if not (map in layer.maps and layer.maps[map]):
				continue
			var map_layer_texture = layer.maps[map]
			
			var blending_layer : BlendingLayer
			if layer.mask:
				blending_layer = BlendingLayer.new(
					"texture({layer_result}, uv)",
					"normal", 1.0, layer.mask.result)
			else:
				blending_layer = BlendingLayer.new("texture({layer_result}, uv)")
			blending_layer.uniform_types.append("sampler2D")
			blending_layer.uniform_names.append("layer_result")
			blending_layer.uniform_values.append(map_layer_texture.result)
			blending_layers.append(blending_layer)
		
		if blending_layers.empty():
			results.erase(map)
			continue
		
		var result : Texture = yield(LayerBlendViewportManager.blend(
				blending_layers, Globals.result_size,
				get_instance_id() + map.hash(), shader_dirty), "completed")
		
		results[map] = result


func get_map_result(map : String) -> Texture:
	if not map in results:
		return null
	return results[map]
