extends MeshInstance

onready var text_label : Label = $Viewport/Text
onready var viewport : Viewport = $Viewport
onready var life_timer : Timer = $LifeTimer

func setup(text : String, position : Vector3, color := Color.red, life_time := 10.0) -> void:
	global_transform.origin = position
	
	text_label.text = text
	text_label.modulate = color
	yield(get_tree(), "idle_frame")
	viewport.size = text_label.get_rect().size
	
	life_timer.wait_time = life_time
	life_timer.start()
	
	var viewport_texture := viewport.get_texture()
	material_override.albedo_texture = viewport_texture
