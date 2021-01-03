extends Resource

"""
A folder layer containing `MaterialLayer`s used in a `LayerMaterial` for
organization and optimization
"""

# warning-ignore-all:unused_class_variable
export var name := "Untitled Folder"
export var visible := true
export var layers : Array

var parent
var dirty := false
var shader_dirty := false

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
