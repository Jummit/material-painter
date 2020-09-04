extends MeshInstance

"""
A colored text that is drawn ontop of everything

Uses a viewport to generate the texture for the quad.
"""

onready var viewport : Viewport = $Viewport
onready var text_label : Label = $Viewport/Text

func setup(text : String, position : Vector3, color := Color.red,
		life_time := 10.0) -> void:
	global_transform.origin = position
	
	text_label.text = text
	text_label.modulate = color
	viewport.size = text_label.get_rect().size
	material_override.albedo_texture = viewport.get_texture()
	
	yield(get_tree().create_timer(life_time), "timeout")
	queue_free()
