extends Node

onready var view_to_texture_viewport : Viewport = $ViewToTextureViewport
onready var texture_to_view_viewport : Viewport = $TextureToViewViewport
onready var seams_viewport : Viewport = $SeamsViewport
onready var view_to_texture_camera : Camera = $ViewToTextureViewport/Camera
onready var texture_to_view_mesh_instance : MeshInstance = $TextureToViewViewport/MeshInstance
onready var view_to_texture_mesh_instance : MeshInstance = $ViewToTextureViewport/MeshInstance

func get_textures() -> Dictionary:
	return {
		view_to_texture = view_to_texture_viewport.get_texture(),
		texture_to_view = texture_to_view_viewport.get_texture(),
		seams = seams_viewport.get_texture(),
	}


func set_mesh(mesh_instance : MeshInstance) -> void:
	texture_to_view_mesh_instance.mesh = mesh_instance.mesh
	view_to_texture_mesh_instance.mesh = mesh_instance.mesh
	texture_to_view_mesh_instance.material_override.set_shader_param("model_transform", mesh_instance.transform)
	
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE


func update_view(viewport : Viewport):
	var camera := viewport.get_camera()
	view_to_texture_viewport.size = 2.0 * viewport.size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	var texture_to_view_material := texture_to_view_mesh_instance.material_override
	texture_to_view_material.set_shader_param("fovy_degrees", camera.fov)
	texture_to_view_material.set_shader_param("z_near", camera.near)
	texture_to_view_material.set_shader_param("z_far", camera.far)
	texture_to_view_material.set_shader_param("aspect", viewport.size.x / viewport.size.y)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
