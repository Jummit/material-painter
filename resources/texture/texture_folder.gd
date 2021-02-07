extends Resource

"""
A folder layer containing `TextureLayer`s used in a `LayerTexture` for organization
"""

# warning-ignore-all:unused_class_variable
export var name := "Untitled Folder"
export var visible := true
export var layers : Array
export var opacity := 1.0
export var blend_mode := "normal"

var parent
var result : Texture
var dirty := false
var shader_dirty := false
var icon : Texture

const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init():
	resource_local_to_scene = true
	# for some reason, NOTIFICATION_POSTINITIALIZE doesn't fire,
	# so use this hack instead
	yield(VisualServer, "frame_post_draw")
	for layer in layers:
		layer.parent = self


func get_layer_texture_in() -> Resource:
	# hacky workaround to avoid cycling references
	if parent.has_method("get_layer_texture_in"):
		return parent.get_layer_texture_in()
	else:
		return parent


func mark_dirty(shader_too := false) -> void:
	dirty = true
	shader_dirty = shader_too
	parent.mark_dirty(shader_dirty)


func update(force_all := false) -> void:
	if not dirty and not force_all:
		return
	var blending_layers := []
	for layer in layers:
		if not layer.visible:
			continue
		var shader_layer = layer._get_as_shader_layer()
		if shader_layer is GDScriptFunctionState:
			shader_layer = yield(shader_layer, "completed")
		blending_layers.append(shader_layer)
	result = yield(LayerBlendViewportManager.blend(blending_layers,
			Constants.result_size, get_instance_id(), shader_dirty), "completed")


func _get_as_shader_layer() -> BlendingLayer:
	var layer := BlendingLayer.new("texture({texture}, uv)", blend_mode, opacity)
	layer.uniform_types.append("sampler2D")
	layer.uniform_names.append("texture")
	layer.uniform_values.append(result)
	return layer
