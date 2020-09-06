extends Viewport

const TextureUtils = preload("res://utils/texture_utils.gd")

func render_texture(subject : Node, result_size : Vector2) -> Texture:
	add_child(subject)
	size = result_size
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	var result := TextureUtils.viewport_to_image(get_texture())
	subject.queue_free()
	return result
