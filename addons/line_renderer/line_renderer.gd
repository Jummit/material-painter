extends Viewport

"""
`Viewport` that renders a set of smooth colored lines using shaders
"""

onready var background_rect : ColorRect = $BackgroundRect

func render_lines(lines : PoolVector2Array, colors : PoolColorArray,
		result_size : Vector2, thickness := 0.02,
		background_color := Color.white) -> ImageTexture:
	size = result_size
	background_rect.color = background_color
	background_rect.rect_size = result_size
	
	for line in range(0, lines.size(), 2):
		var line_rect := ColorRect.new()
		line_rect.rect_size = result_size
		line_rect.material = ShaderMaterial.new()
		line_rect.material.shader = preload("line.shader")
		line_rect.material.set_shader_param("a", lines[line])
		line_rect.material.set_shader_param("b", lines[line + 1])
		line_rect.material.set_shader_param("col", colors[line / 2.0])
		line_rect.material.set_shader_param("size", thickness)
		add_child(line_rect)
	
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	
	for line in range(1, get_child_count()):
		get_child(line).queue_free()
	
	var image_texture := ImageTexture.new()
	image_texture.create_from_image(get_texture().get_data())
	return image_texture
