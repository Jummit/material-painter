extends Node

var mesh_instance : MeshInstance setget set_mesh_instance
# warning-ignore:unused_class_variable
onready var result : ViewportTexture = $PaintViewport.get_texture()

var _painting := false
var _next_position : Vector2

onready var paint_material : ShaderMaterial = $PaintViewport/PaintRect.material
onready var paint_viewport : Viewport = $PaintViewport
onready var initial_texture_rect : TextureRect = $PaintViewport/InitialTextureRect
onready var view_to_texture_viewport : Viewport = $ViewToTextureViewport
onready var texture_to_view_viewport : Viewport = $TextureToViewViewport
onready var seams_viewport : Viewport = $SeamsViewport
onready var view_to_texture_camera : Camera = $ViewToTextureViewport/Camera
onready var texture_to_view_mesh_instance : MeshInstance = $TextureToViewViewport/MeshInstance
onready var view_to_texture_mesh_instance : MeshInstance = $ViewToTextureViewport/MeshInstance
onready var seams_rect_material : ShaderMaterial = $SeamsViewport/SeamsRect.material

func _ready() -> void:
	seams_rect_material.set_shader_param("texture_to_view", texture_to_view_viewport.get_texture())
	paint_material.set_shader_param("seams", seams_viewport.get_texture())
	paint_material.set_shader_param("texture_to_view", texture_to_view_viewport.get_texture())
	texture_to_view_mesh_instance.material_override.set_shader_param("view_to_texture", view_to_texture_viewport.get_texture())


func set_initial_texture(texture : Texture) -> void:
	initial_texture_rect.show()
	initial_texture_rect.texture = texture
	paint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	initial_texture_rect.hide()


func paint(from : Vector2, to : Vector2) -> void:
	if _painting:
		_next_position = from
	_painting = true
	paint_material.set_shader_param("brush_pos", from)
	paint_material.set_shader_param("brush_ppos", from)
	paint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	_painting = false
	if _next_position != Vector2.ZERO:
		_next_position = Vector2.ZERO
		paint(to, _next_position)


func set_mesh_instance(to : MeshInstance) -> void:
	mesh_instance = to
	texture_to_view_mesh_instance.mesh = mesh_instance.mesh
	view_to_texture_mesh_instance.mesh = mesh_instance.mesh
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE


func update_view(viewport : Viewport) -> void:
	var camera := viewport.get_camera()
	
	view_to_texture_viewport.size = 2.0 * viewport.size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_camera.near = camera.near
	view_to_texture_camera.far = camera.far
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	
	yield(VisualServer, "frame_post_draw")
	
	var texture_to_view_material := texture_to_view_mesh_instance.material_override
	texture_to_view_material.set_shader_param("model_transform", camera.global_transform.affine_inverse() * mesh_instance.global_transform)
	texture_to_view_material.set_shader_param("fovy_degrees", camera.fov)
	texture_to_view_material.set_shader_param("z_near", camera.near)
	texture_to_view_material.set_shader_param("z_far", camera.far)
	texture_to_view_material.set_shader_param("aspect", viewport.size.x / viewport.size.y)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE


func clear() -> void:
	initial_texture_rect.texture = null
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
