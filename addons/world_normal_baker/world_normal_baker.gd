extends Viewport

func bake_world_normal(mesh : Mesh, result_size : Vector2,
		surface : int) -> ViewportTexture:
	# Todo: use correct surface.
	size = result_size
	$MeshInstance.mesh = mesh
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()
