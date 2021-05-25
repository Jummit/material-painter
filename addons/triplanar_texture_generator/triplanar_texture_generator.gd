extends Viewport

"""
A `Viewport` to render a triplanar texture in UV-space
"""

onready var mesh_instance : MeshInstance = $MeshInstance
onready var material : ShaderMaterial = mesh_instance.material_override

func get_triplanar_texture(texture : Texture, mesh : Mesh,
		result_size : Vector2, uv_scale := Vector3.ONE,
		uv_offset := Vector3.ZERO, blend_sharpness := 5.0) -> Texture:
	size = result_size
	mesh_instance.mesh = mesh
	material.set_shader_param("albedo", texture)
	material.set_shader_param("uv_scale", uv_scale)
	material.set_shader_param("uv_offset", uv_offset)
	material.set_shader_param("uv_blend_sharpness", blend_sharpness)
	render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return get_texture()
