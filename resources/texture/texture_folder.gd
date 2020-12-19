extends Resource

"""
A folder layer used in a `LayerTexture` for organization and optimization
"""

# warning-ignore-all:unused_class_variable
export var name := "Untitled Folder"
export var visible := true
export var layers : Array

var parent

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
