extends Viewport

func generate_world_map(mesh : Mesh, result_size : Vector2) -> Texture:
	size = result_size
	$MeshInstance.mesh = mesh
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()
