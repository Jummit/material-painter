tool
extends Panel

"""
A panel which can be repositioned by dragging the title above other windows

It draws the preview if a windew is being dragged above it.
It is holds the logic for rearranging the node structure after a window has
been repositioned.

Windows can be popped out by pressing a button which makes them floating windows.
"""

export var title := "" setget set_title

onready var drag_receiver : Control = get_tree().root.find_node(
	"WindowDragReceiver", true, false)

# used for storing/restoring layouts
# warning-ignore:unused_class_variable
onready var original_path := get_path()

const PlacementUtils := preload("placement_utils.gd")

func _ready() -> void:
	$Title.set_drag_forwarding(self)
	drag_receiver.connect("draw", self, "on_WindowDragReceiver_draw")


func _notification(what : int) -> void:
	if what == NOTIFICATION_PARENTED:
		if get_parent() is TabContainer:
			get_parent().set_tab_title(get_index(), title)
		if get_parent() is TabContainer or get_parent() is WindowDialog:
			$Title.hide()
		else:
			$Title.show()


func set_title(to) -> void:
	title = to
	$Title.text = to
	if get_parent() is TabContainer:
		get_parent().set_tab_title(get_index(), title)


func _on_PopInOutButton_pressed():
	if get_parent() is WindowDialog:
		pop_in()
	else:
		pop_out()


func on_WindowDragReceiver_draw() -> void:
	var placement := get_placement(
		PlacementUtils.get_window_from_drag_data(
		get_tree(), get_viewport().gui_get_drag_data()))
	if not placement:
		return
	var third_size := rect_size / 3.0
	var rect := Rect2(Vector2(), third_size)
	if placement.horizontal:
		rect.size.y = rect_size.y
	elif placement.vertical:
		rect.size.x = rect_size.x
	if placement.right:
		rect.position.x = third_size.x * 2
	elif placement.bottom:
		rect.position.y = third_size.y * 2
	if placement.middle:
		rect.position = third_size
	rect.position += rect_global_position
	drag_receiver.preview.draw(
				drag_receiver.get_canvas_item(), rect)


func get_drag_data_fw(_position : Vector2, _control : Container):
	return {
		type = "window",
		window = self,
	}


func place_window_ontop(window : Panel) -> bool:
	var placement := get_placement(window)
	if not placement:
		return false
	
	if get_parent() is TabContainer:
		if placement.middle:
			place_window_into_tabs(window)
		elif window == self:
			place_self_on_tabs(placement)
		else:
			place_window_on_tabs(window, placement)
	elif window.get_parent() == get_parent():
		place_window_with_same_parent(window, placement)
	else:
		place_window_normal(window, placement)
	return true

# container
# ┣ window
# ┗ self
#     ↓
# new_container
# ┣ window
# ┗ self
func place_window_with_same_parent(window : Panel,
		placement : PlacementUtils.WindowPlacement) -> void:
	var new_container := placement.get_container(window)
	get_parent().replace_by(new_container)
	new_container.move_child(window, placement.index)

# container
# ┣ other_window
# ┗ self
#      ↓
# container
# ┣ other_window
# ┗ new_container
#   ┣ self
#   ┗ window
func place_window_normal(window : Panel,
	placement : PlacementUtils.WindowPlacement) -> void:
	remove_from_container(window)
	
	var parent := get_parent()
	parent.remove_child(self)
	
	var new_container := placement.get_container(window)
	new_container.add_child(self)
	new_container.add_child(window)
	parent.add_child(new_container)
	new_container.move_child(window, placement.index)
	update_size(parent)

# tab_container
# ┣ self
# ┗ other_window
#     ↓
# tab_container
# ┣ self
# ┣ other_window
# ┗ window
func place_window_into_tabs(window : Panel) -> void:
	remove_from_container(window)
	get_parent().add_child(window)


# tab_container
# ┣ other_window
# ┗ self
#    ↓
# new_container
# ┣ tab_container
# ┃ ┣ other_window
# ┃ ┗ self
# ┗ window

# container
# ┣ tab_container
# ┃ ┣ other_window
# ┃ ┗ self
# ┗ window
#    ↓
# new_container
# ┣ tab_container
# ┃ ┣ other_window
# ┃ ┗ self
# ┗ window
func place_window_on_tabs(window : Panel,
	placement : PlacementUtils.WindowPlacement) -> void:
	if window.get_parent() == get_parent().get_parent():
		window.get_parent().replace_by(placement.get_container(window))
		return
	
	var parent_container := get_parent().get_parent()
	var tab_container : TabContainer = get_parent()
	var old_index := tab_container.get_index()
	remove_from_container(window)
	
	parent_container.remove_child(tab_container)
	
	var new_container := placement.get_container(window)
	new_container.add_child(tab_container)
	new_container.add_child(window)
	new_container.move_child(window, placement.index)
	
	parent_container.add_child(new_container)
	parent_container.move_child(new_container, old_index)
	update_size(new_container)


# tab_container
# ┣ other_window
# ┣ another_window
# ┗ self
#      ↓
# new_container
# ┣ tab_container
# ┃ ┣ other_window
# ┃ ┗ another_window
# ┗ self

# tab_container
# ┣ other_window
# ┗ self
#      ↓
# new_container
# ┃ other_window
# ┗ self
func place_self_on_tabs(placement : PlacementUtils.WindowPlacement) -> void:
	if get_parent().get_child_count() <= 2:
		get_parent().replace_by(placement.get_container(self))
	else:
		place_window_on_tabs(self, placement)


# container
# ┣ window
# ┗ other_window
#      ↓
# other_window

# container
# ┣ window
# ┣ other_window
# ┗ another_window
#      ↓
# container
# ┣ other_window
# ┗ another_window
func remove_from_container(window : Panel) -> void:
	var parent := window.get_parent()
	var original_index := parent.get_index()
	parent.remove_child(window)
	window.show()
	if parent is WindowDialog:
		parent.free()
	elif parent.get_child_count() <= 1:
		var other_window = parent.get_child(0)
		parent.remove_child(other_window)
		other_window.show()
		parent.get_parent().add_child(other_window)
		parent.get_parent().move_child(other_window, original_index)
		parent.free()


func update_size(container : Control) -> void:
	container.rect_position = Vector2.ZERO
	container.anchor_right = 1
	container.anchor_bottom = 1
	container.margin_right = 0
	container.margin_bottom = 0


func get_placement(window : Panel) -> PlacementUtils.WindowPlacement:
	if (not window) or (not visible) or (window == self and not get_parent() is TabContainer):
		return null
	var placement := PlacementUtils.get_drop_placement(self)
	return placement


func pop_out() -> void:
	remove_from_container(self)
	put_in_window()


func put_in_window() -> WindowDialog:
	var window := WindowDialog.new()
	window.window_title = title
	# don't use `popup_centered`, as it makes the popup modal
	# see `Control.show_modal`
	window.get_close_button().hide()
	window.resizable = true
	# move the window down because the title bar is rendered above
	window.rect_position = get_rect().position + Vector2(0, 20)
	window.rect_size = rect_size
	# `WindowDialog` doesn't use child minimum size
	window.rect_min_size = rect_min_size
	window.add_child(self)
	drag_receiver.get_parent().add_child(window)
	window.show()
	update_size(self)
	$PopInOutButton.text = "v"
	$PopInOutButton.hint_tooltip = "Pop window in"
	return window


func pop_in() -> void:
	get_tree().call_group("Windows", "place_window_ontop", self)
	$PopInOutButton.text = "^"
	$PopInOutButton.hint_tooltip = "Pop window out"
