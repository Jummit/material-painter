extends Node

onready var texture_to_view_mesh_instance : MeshInstance = $TextureToViewViewport/MeshInstance
onready var view_to_texture_mesh_instance : MeshInstance = $ViewToTextureViewport/MeshInstance
onready var view_to_texture_viewport : Viewport = $ViewToTextureViewport
onready var texture_to_view_viewport : Viewport = $TextureToViewViewport
onready var seams_viewport : Viewport = $SeamsViewport

func generate_textures_from_mesh(mesh : Mesh) -> Dictionary:
	texture_to_view_mesh_instance.mesh = mesh
	view_to_texture_mesh_instance.mesh = mesh
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	return {
		view_to_texture = view_to_texture_viewport.get_texture(),
		texture_to_view = texture_to_view_viewport.get_texture(),
		seams = seams_viewport.get_texture(),
	}
