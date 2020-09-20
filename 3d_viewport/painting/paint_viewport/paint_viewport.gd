extends Viewport

onready var paint_rect : ColorRect = $PaintRect
onready var paint_material : ShaderMaterial = $PaintRect.material

func load_utility_textures(textures : Dictionary) -> void:
	paint_material.set_shader_param("tex2view_tex", textures.texture_to_view)
	paint_material.set_shader_param("seams", textures.seams)


func paint(position : Vector2, previous_position : Vector2) -> void:
	paint_material.set_shader_param("brush_pos", position)
	paint_material.set_shader_param("brush_ppos", previous_position)
	render_target_update_mode = Viewport.UPDATE_ONCE
