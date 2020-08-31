static func line(from : Vector3, to : Vector3, color : Color, life_time : float, viewport : Viewport) -> void:
	var line := preload("res://addons/debug_3d/debug_line.tscn").instance()
	viewport.add_child(line)
	line.setup(from, to, color, life_time)

static func text(text : String, position : Vector3, color : Color, life_time : float, viewport : Viewport) -> void:
	var debug_text := preload("res://addons/debug_3d/debug_text.tscn").instance()
	viewport.add_child(debug_text)
	debug_text.setup(text, position, color, life_time)
