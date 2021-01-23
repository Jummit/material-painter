extends Node

"""
A utility to paint meshes in 3D

Implementation is copied and modified from
https://github.com/RodZill4/godot-material-spray.
Uses a number of utility textures generated by shaders to make painting real time.
"""

var mesh_instance : MeshInstance setget set_mesh_instance
var brush : Brush setget set_brush
# warning-ignore:unused_class_variable
onready var result : ViewportTexture = $PaintViewport.get_texture()

var _painting := false
var _next_position : Vector2
var _viewport_size : Vector2
var _cached_images : Dictionary = {}

const Brush = preload("res://addons/painter/brush.gd")

onready var paint_material : ShaderMaterial = $PaintViewport/PaintRect.material
onready var paint_viewport : Viewport = $PaintViewport
onready var paint_rect : ColorRect = $PaintViewport/PaintRect
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
	initial_texture_rect.rect_size = paint_viewport.size
	initial_texture_rect.show()
	initial_texture_rect.texture = texture
	paint_rect.hide()
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	paint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	initial_texture_rect.hide()
	paint_rect.show()


func paint(from : Vector2, to : Vector2) -> void:
	if _painting:
		_next_position = from
	_painting = true
	paint_material.set_shader_param("brush_pos", from)
	paint_material.set_shader_param("brush_ppos", to)
	paint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	_painting = false
	if _next_position != Vector2.ZERO:
		_next_position = Vector2.ZERO
		yield(paint(to, _next_position), "completed")


func set_mesh_instance(to : MeshInstance) -> void:
	mesh_instance = to
	texture_to_view_mesh_instance.mesh = mesh_instance.mesh
	view_to_texture_mesh_instance.mesh = mesh_instance.mesh
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")


func update_view(viewport : Viewport) -> void:
	_viewport_size = viewport.size
	paint_viewport.size = viewport.size
	
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
	
	if brush:
		paint_material.set_shader_param("brush_size", brush.size / viewport.size)
	
	yield(VisualServer, "frame_post_draw")


func set_brush(to : Brush) -> void:
	brush = to
	
	var brush_texture : Texture
	var texture_mask : Texture
	
	if brush.texture:
		brush_texture = _load_image_texture(brush.texture)
	if brush.texture_mask:
		texture_mask = _load_image_texture(brush.texture_mask)
	
	paint_material.set_shader_param("brush_size", brush.size / _viewport_size)
	paint_material.set_shader_param("brush_strength", brush.strength)
	paint_material.set_shader_param("brush_texture", brush_texture)
	paint_material.set_shader_param("brush_color", brush.color)
	paint_material.set_shader_param("pattern_scale", brush.pattern_scale)
	paint_material.set_shader_param("texture_angle", brush.texture_angle)
	paint_material.set_shader_param("stamp_mode", brush.stamp_mode)
	paint_material.set_shader_param("texture_mask", texture_mask)


func clear() -> void:
	initial_texture_rect.texture = null
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
	yield(VisualServer, "frame_post_draw")


func _load_image_texture(path : String) -> ImageTexture:
	if path in _cached_images:
		return _cached_images[path]
	var image := Image.new()
	image.load(path)
	var image_texture := ImageTexture.new()
	image_texture.create_from_image(image)
	_cached_images[path] = image_texture
	return image_texture
