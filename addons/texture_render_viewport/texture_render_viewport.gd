extends Viewport

func render_texture(subject : Node, result_size : Vector2) -> ViewportTexture:
	add_child(subject)
	size = result_size
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	subject.queue_free()
	return get_texture()
