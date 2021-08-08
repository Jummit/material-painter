extends LineEdit

"""
A number slider similar to that found in Godot Engine's inspector
"""

# Emitted when the user changes the value by sliding or by typing it in.
signal changed

# The current number.
export var value : float setget set_value
# The mininum value allowed by sliding. Smaller numbers can be inputed manually.
export var min_value : float
# The maximum value allowed.
export var max_value : float = 10
# The number the value will be snapped to. Useful for integer inputs.
export var step : float
# The sensitivity while sliding.
export var sensitivity := 1000.0

# If the user is dragging the text field.
var _dragging := false
var _dragged_position : Vector2
# If the user has grabbed the slider grabber.
var _grabbed := false
var _clicked := false
var _text_editing := false

func _input(event : InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseMotion:
		update()
	var button_ev := event as InputEventMouseButton
	var motion_ev := event as InputEventMouseMotion
	if button_ev:
		var in_rect := get_global_rect().has_point(button_ev.position)
		if not button_ev.pressed:
			if _grabbed:
				_grabbed = false
			elif _dragging:
				_dragging = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				warp_mouse(_dragged_position)
			elif in_rect and _clicked:
				mouse_filter = Control.MOUSE_FILTER_STOP
				grab_focus()
		_clicked = button_ev.pressed and in_rect
	if motion_ev and motion_ev.button_mask == BUTTON_LEFT:
		var in_rect := get_global_rect().has_point(motion_ev.position)
		if _grabbed:
			value = _correct(range_lerp(motion_ev.position.x,
					rect_global_position.x,
					rect_global_position.x + rect_size.x, min_value, max_value))
			text = str(value)
			emit_signal("changed")
		elif _dragging:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			release_focus()
			value += motion_ev.relative.x * ((max_value - min_value) / sensitivity) * _get_change_modifier()
			value = _correct(value)
			text = str(value)
			emit_signal("changed")
		elif _mouse_near_grabber() and _clicked:
			_grabbed = true
		elif in_rect and _clicked:
			_dragged_position = motion_ev.position - rect_global_position
			_dragging = true
	update()


func _gui_input(event : InputEvent) -> void:
	if event.is_action("ui_cancel"):
		release_focus()
		text = str(value)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2(0, rect_size.y), Vector2(rect_size.x, 2)),
			Color.dimgray)
	if not _text_editing and (_dragging or _grabbed or Rect2(Vector2.ZERO, rect_size + Vector2.DOWN * 10).has_point(
				get_local_mouse_position())):
		var texture := preload("grabber.svg")
		if _mouse_near_grabber() or _grabbed:
			texture = preload("selected_grabber.svg")
		draw_texture(texture, _get_grabber_pos() - texture.get_size() / 2)
	else:
		var size := Vector2(4, 2)
		draw_rect(Rect2(_get_grabber_pos() - Vector2.RIGHT * 2, size), Color.white)


func set_value(to) -> void:
	value = to
	text = str(value)


func _get_change_modifier() -> float:
	return .2 if Input.is_key_pressed(KEY_SHIFT) else 1.0


func _correct(new_value : float) -> float:
	return stepify(clamp(stepify(new_value, step), min_value, max_value), 0.001)


func _get_grabber_pos() -> Vector2:
	return Vector2(range_lerp(value, min_value, max_value, 0, rect_size.x),
			rect_size.y)


func _mouse_near_grabber() -> bool:
	return get_local_mouse_position().distance_to(_get_grabber_pos()) < 10


func _on_focus_entered() -> void:
	_text_editing = true


func _on_focus_exited():
	text = str(value)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_editing = false


func _on_text_changed(new_text : String) -> void:
	if new_text.is_valid_float():
		value = _correct(float(new_text))
		emit_signal("changed")


func _on_text_entered(new_text : String) -> void:
	value = _correct(float(new_text))
	release_focus()
	text = str(value)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
