extends Viewport

"""
A `Viewport` to render the position map of a mesh in UV-space
"""

onready var mesh_instance : MeshInstance = $MeshInstance

func generate_world_map(mesh : Mesh, result_size : Vector2,
		_surface : int) -> ViewportTexture:
	# Todo: use correct surface.
	size = result_size
	mesh_instance.mesh = mesh
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()
