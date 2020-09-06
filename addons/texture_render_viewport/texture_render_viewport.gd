extends Viewport

var busy := false

const TextureUtils = preload("res://utils/texture_utils.gd")

func render_texture(subject : Node, result_size : Vector2) -> Texture:
	while busy:
		yield(VisualServer, "frame_post_draw")
	add_child(subject)
	size = result_size
	render_target_update_mode = Viewport.UPDATE_ONCE
	busy = true
	yield(VisualServer, "frame_post_draw")
	busy = false
	var result := TextureUtils.viewport_to_image(get_texture())
	subject.queue_free()
	return result
