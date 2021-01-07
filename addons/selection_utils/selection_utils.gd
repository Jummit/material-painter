extends Node

"""
A utility for performing different mesh selections on the GPU

Selections will be added in white ontop of the given texture.
There are multiple `SelectionType`s, each preparing the mesh by setting the
vertex colors of selectable areas the same.
The vertex color at the given screen position is then sampled
and isolated to get the selected area on the texture.
"""

var mesh : Mesh setget set_mesh

var _prepared_meshes := {}
var _selection_types := {
	SelectionType.TRIANGLE : preload("selection_types/triangle_selection.gd"),
	SelectionType.QUAD : preload("selection_types/quad_selection.gd"),
	SelectionType.MESH_ISLAND : preload("selection_types/mesh_island_selection.gd"),
	SelectionType.UV_ISLAND : preload("selection_types/uv_island_selection.gd"),
	SelectionType.FLAT_SURFACE : preload("selection_types/flat_surface_selection.gd"),
}

enum SelectionType {
	TRIANGLE,
	QUAD,
	MESH_ISLAND,
	UV_ISLAND,
	FLAT_SURFACE,
}

onready var isolate_viewport : Viewport = $IsolateViewport
onready var base_texture_mesh : MeshInstance = $IsolateViewport/BaseTextureMesh
onready var isolate_mesh_instance : MeshInstance = $IsolateViewport/MeshInstance

onready var sample_camera : Camera = $ScreenSampleViewport/Camera
onready var sample_mesh_instance : MeshInstance = $ScreenSampleViewport/MeshInstance
onready var screen_sample_viewport : Viewport = $ScreenSampleViewport
onready var pixel_sample_viewport : Viewport = $PixelSampleViewport
onready var screen_viewport_texture : TextureRect = $PixelSampleViewport/ScreenViewportTexture

func update_view(viewport : Viewport) -> void:
	screen_sample_viewport.size = viewport.size
	screen_viewport_texture.rect_size = viewport.size
	sample_camera.global_transform = viewport.get_camera().global_transform
	sample_camera.fov = viewport.get_camera().fov
	sample_camera.far = viewport.get_camera().far
	sample_camera.near = viewport.get_camera().near


func add_selection(selection_type : int, mouse_position : Vector2,
		result_size : Vector2, onto : Texture = null,
		color := Color.white) -> Texture:
	sample_mesh_instance.mesh = _prepared_meshes[selection_type]
	screen_sample_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	pixel_sample_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	screen_viewport_texture.rect_position = -mouse_position
	yield(VisualServer, "frame_post_draw")
	
	var screen_data := pixel_sample_viewport.get_texture().get_data()
	screen_data.lock()
	var clicked_id := screen_data.get_pixel(0, 0)
	
	if onto:
		base_texture_mesh.material_override.set_shader_param("albedo", onto)
	isolate_mesh_instance.mesh = _prepared_meshes[selection_type]
	isolate_mesh_instance.material_override.set_shader_param("id", Vector3(clicked_id.r, clicked_id.g, clicked_id.b))
	isolate_mesh_instance.material_override.set_shader_param("color", color)
	isolate_viewport.size = result_size
	isolate_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	
	return isolate_viewport.get_texture()


func set_mesh(to : Mesh) -> void:
	mesh = to
	for selection_type in _selection_types:
		var result = _selection_types[selection_type].prepare_mesh(mesh)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		_prepared_meshes[selection_type] = result
