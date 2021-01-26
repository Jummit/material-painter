extends Control

"""
A `Control` that is used for dropping windows anywhere and preview rendering

Shows itself if a window is being dragged. If the window is dropped, tries to
place the window on all other windows until it is successfull.
"""

# warning-ignore:unused_class_variable
export var preview : StyleBox = preload("drop_preview.stylebox")

const PlacementUtils := preload("placement_utils.gd")

func _input(_event : InputEvent) -> void:
	visible = PlacementUtils.get_window_from_drag_data(
			get_tree(), get_viewport().gui_get_drag_data()) != null and\
			is_window_on_pos(get_global_mouse_position())
	update()


func can_drop_data(_position: Vector2, data) -> bool:
	return PlacementUtils.get_window_from_drag_data(get_tree(), data) != null


func drop_data(_position : Vector2, data) -> void:
	var window_data := PlacementUtils.get_window_from_drag_data(get_tree(), data)
	for window in get_tree().get_nodes_in_group("Windows"):
		if window.place_window_ontop(window_data):
			break


# used to determine if the drag receiver should be shown
# makes it possible for tabs to be rearranged
func is_window_on_pos(pos : Vector2) -> bool:
	for window in get_tree().get_nodes_in_group("Windows"):
		if window.get_global_rect().has_point(pos) and window.visible:
			return true
	return false
