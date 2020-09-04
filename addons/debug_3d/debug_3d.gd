"""
A utility for drawing debug shapes in 3D.
The debug shapes have a color, position and will dissapear after a set `life_time`.
"""

static func line(from : Vector3, to : Vector3, color : Color,
		life_time : float, viewport : Viewport) -> void:
	var debug_line := preload("res://addons/debug_3d/debug_line/debug_line.tscn").instance()
	viewport.add_child(debug_line)
	debug_line.setup(from, to, color, life_time)


static func text(text : String, position : Vector3, color : Color,
		life_time : float, viewport : Viewport) -> void:
	var debug_text := preload("res://addons/debug_3d/debug_text/debug_text.tscn").instance()
	viewport.add_child(debug_text)
	debug_text.setup(text, position, color, life_time)
