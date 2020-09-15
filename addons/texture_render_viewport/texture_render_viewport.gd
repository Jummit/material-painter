extends Viewport

var busy := false

func render_texture(subject : Node, result_size : Vector2) -> ViewportTexture:
	while busy:
		yield(VisualServer, "frame_post_draw")
	add_child(subject)
	size = result_size
	render_target_update_mode = Viewport.UPDATE_ONCE
	busy = true
	yield(VisualServer, "frame_post_draw")
	busy = false
	subject.queue_free()
	return get_texture()
