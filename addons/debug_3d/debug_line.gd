extends MeshInstance

onready var life_timer : Timer = $LifeTimer

func setup(from : Vector3, to : Vector3, color := Color.red, life_time := 10.0) -> void:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	surface_tool.add_color(color)
	surface_tool.add_vertex(from)
	surface_tool.add_color(color)
	surface_tool.add_vertex(to)
	mesh = surface_tool.commit()
	
	life_timer.wait_time = life_time
	life_timer.start()
