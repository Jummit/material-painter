extends Node

var mesh : Mesh setget set_mesh

var _prepared_meshes := {}
var _selection_types := {
	SelectionType.TRIANGLE : preload("selection_types/triangle_selection.gd")
}

enum SelectionType {
	TRIANGLE,
	QUAD,
	MESH_ISLAND,
	UV_ISLAND,
}

onready var isolate_viewport : Viewport = $IsolateViewport
onready var isolate_mesh_instance : MeshInstance = $IsolateViewport/MeshInstance
onready var sample_viewport : Viewport = $SampleViewport
onready var sample_mesh_instance : MeshInstance = $SampleViewport/MeshInstance
onready var sample_camera : Camera = $SampleViewport/Camera
onready var base_texture_mesh : MeshInstance = $IsolateViewport/BaseTextureMesh

func update_view(viewport : Viewport) -> void:
	sample_viewport.size = viewport.size
	sample_camera.global_transform = viewport.get_camera().global_transform
	sample_camera.fov = viewport.get_camera().fov
	sample_camera.far = viewport.get_camera().far
	sample_camera.near = viewport.get_camera().near


# warning-ignore:unused_argument
func add_selection(selection_type : int, mouse_position : Vector2,
		result_size : Vector2, onto : Texture) -> Texture:
	sample_mesh_instance.mesh = _prepared_meshes[selection_type]
	sample_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	
	var screen_data := sample_viewport.get_texture().get_data()
	screen_data.lock()
	var clicked_id := screen_data.get_pixelv(mouse_position)
	
	base_texture_mesh.material_override.set_shader_param("albedo", onto)
	isolate_mesh_instance.mesh = _prepared_meshes[selection_type]
	isolate_mesh_instance.material_override.set_shader_param("id", clicked_id.r)
	isolate_viewport.size = result_size
	isolate_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	
	return isolate_viewport.get_texture()


func set_mesh(to) -> void:
	mesh = to
	for selection_type in _selection_types:
		var result = _selection_types[selection_type].prepare_mesh(mesh)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		_prepared_meshes[selection_type] = result
