#  1/3  1/3   1/3
# +--------------+
# |   | Top  |   | 1/3
# | L +------+ R |
# | e |Middle| i | 1/3
# | f |      | g |
# | t +------+ h |
# |   |Bottom| t | 1/3
# +--------------+

class WindowPlacement:
	var left : bool
	var right : bool
	var top : bool
	var bottom : bool
	var vertical : bool
	var horizontal : bool
	var middle : bool
	var first : bool
	var index : int
	var _position : Vector2
	
	func _init(x : int, y : int) -> void:
		_position = Vector2(x, y)
		if _position == Vector2.ZERO:
			middle = true
		else:
			horizontal = abs(x)
			vertical = not horizontal
		top = _position == Vector2.UP
		bottom = _position == Vector2.DOWN
		left = _position == Vector2.LEFT
		right = _position == Vector2.RIGHT
		first = left or top
		index = 0 if first else 1
	
	func get_container(window : Panel = null) -> Container:
		if middle:
			var container := TabContainer.new()
			container.drag_to_rearrange_enabled = true
			return container
		var container : SplitContainer
		if horizontal:
			container = HSplitContainer.new()
			if window:
				container.split_offset = int(window.rect_size.x / 2.0)
		elif vertical:
			container = VSplitContainer.new()
			if window:
				container.split_offset = int(window.rect_size.y / 2.0)
		return container
	
	func _to_string() -> String:
		match _position:
			Vector2.LEFT:
				return "Left"
			Vector2.RIGHT:
				return "Right"
			Vector2.UP:
				return "Top"
			Vector2.DOWN:
				return "Bottom"
			Vector2.ZERO:
				return "Middle"
		return ""

static func get_drop_placement(panel : Panel) -> WindowPlacement:
	var mouse := panel.get_local_mouse_position()
	var third_size:= panel.rect_size / 3.0
	if not Rect2(Vector2(), panel.rect_size).has_point(mouse):
		return null
	if mouse.x < third_size.x:
		return WindowPlacement.new(-1, 0)
	elif mouse.x > third_size.x * 2:
		return WindowPlacement.new(1, 0)
	elif mouse.y < third_size.y:
		return WindowPlacement.new(0, -1)
	elif mouse.y > third_size.y * 2:
		return WindowPlacement.new(0, 1)
	else:
		return WindowPlacement.new(0, 0)


static func get_window_from_drag_data(tree : SceneTree, data) -> Panel:
	if data is Dictionary and "type" in data:
		match data.type:
			"window":
				return data.window
			"tabc_element":
				return tree.root.get_node(data.from_path).\
					get_child(data.tabc_element) as Panel
	return null
