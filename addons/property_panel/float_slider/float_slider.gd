extends LineEdit

export(float, 0, 3) var value : float
export(float, 0, 3) var min_value : float
var max_value : float = 10
var step : float

var _dragging := false
var _sensitivity := 1000.0
var _grabbed := false

signal changed

func _ready():
	text = str(value)


func _input(event) -> void:
	if event is InputEventMouseMotion:
		update()
	if event is InputEventMouseButton:
		var in_rect := get_global_rect().has_point(event.position)
		if event.pressed:
			if mouse_near_grabber():
				_grabbed = true
			elif in_rect:
				_dragging = true
			release_focus()
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif in_rect:
			mouse_filter = Control.MOUSE_FILTER_STOP
			grab_focus()
		else:
			_grabbed = false
			if _dragging:
				_dragging = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				yield(get_tree(), "idle_frame")
				warp_mouse(rect_size / 2)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_LEFT:
		if _grabbed:
			value = correct(range_lerp(event.position.x, rect_global_position.x, rect_global_position.x + rect_size.x, min_value, max_value))
			text = str(value)
			emit_signal("changed")
		elif _dragging:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			value += event.relative.x * ((max_value - min_value) / _sensitivity) * get_change_modifier()
			value = correct(value)
			text = str(value)
			emit_signal("changed")
	update()


func _gui_input(event):
	if event.is_action("ui_cancel"):
		release_focus()
		text = str(value)
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw():
	draw_rect(Rect2(Vector2(0, rect_size.y), Vector2(rect_size.x, 2)),
			Color.dimgray)
	if _dragging or _grabbed or Rect2(Vector2.ZERO, rect_size + Vector2.DOWN * 10).has_point(
				get_local_mouse_position()):
		var texture := preload("grabber.svg")
		if mouse_near_grabber() or _grabbed:
			texture = preload("selected_grabber.svg")
		draw_texture(texture, get_grabber_pos() - texture.get_size() / 2)
	else:
		var size := Vector2(4, 2)
		draw_rect(Rect2(get_grabber_pos() - Vector2.RIGHT * 2, size), Color.white)


func _on_text_changed(new_text : String) -> void:
	if new_text.is_valid_float():
		value = correct(float(new_text))
		emit_signal("changed")


func _on_text_entered(new_text : String) -> void:
	value = correct(float(new_text))
	release_focus()
	text = str(value)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_focus_exited():
	text = str(value)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_change_modifier() -> float:
	return .2 if Input.is_key_pressed(KEY_SHIFT) else 1.0


func correct(new_value : float) -> float:
	return stepify(clamp(stepify(new_value, step), min_value, max_value), 0.001)


func get_grabber_pos() -> Vector2:
	return Vector2(range_lerp(value, min_value, max_value, 0, rect_size.x),
			rect_size.y)


func mouse_near_grabber() -> bool:
	return get_local_mouse_position().distance_to(get_grabber_pos()) < 10
