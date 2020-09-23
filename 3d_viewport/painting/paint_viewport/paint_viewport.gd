extends Viewport

var painting := false
var next_position : Vector2

#onready var paint_rect : ColorRect = $PaintRect
onready var paint_material : ShaderMaterial = $PaintRect.material

func load_utility_textures(textures : Dictionary) -> void:
	paint_material.set_shader_param("tex2view_tex", textures.texture_to_view)
	paint_material.set_shader_param("seams", textures.seams)


func paint(from : Vector2, to : Vector2) -> void:
	if painting:
		next_position = from
	painting = true
	paint_material.set_shader_param("brush_pos", from)
	paint_material.set_shader_param("brush_ppos", to)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	painting = false
	if next_position != Vector2.ZERO:
		next_position = Vector2.ZERO
		paint(to, next_position)
