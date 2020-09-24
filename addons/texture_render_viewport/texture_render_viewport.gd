extends Viewport

"""
A `Viewport` to render a `subject` to a `ViewportTexture` with a given size
"""

var busy := false

func render_texture(subject : Node, result_size : Vector2, wait_when_busy := false) -> ViewportTexture:
	if busy:
		if wait_when_busy:
			while busy:
				yield(VisualServer, "frame_post_draw")
		else:
			# yield because a `GDScriptFunctionState` is probably expected
			yield()
			return ViewportTexture.new()
	add_child(subject)
	size = result_size
	render_target_update_mode = Viewport.UPDATE_ONCE
	busy = true
	yield(VisualServer, "frame_post_draw")
	busy = false
	subject.queue_free()
	var texture := get_texture()
	texture.flags = Texture.FLAG_MIPMAPS | Texture.FLAG_REPEAT | Texture.FLAG_FILTER
	return texture
