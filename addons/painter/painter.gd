extends Node

"""
A utility to paint meshes in 3D

Implementation is copied and modified from
https://github.com/RodZill4/godot-material-spray.
Uses a number of utility textures generated by shaders to enable painting in
real time.
"""

# The `MeshInstance` of the painted model which provides the `Mesh` and
# `Transform` used to paint.
var mesh_instance : MeshInstance setget set_mesh_instance
# Which surface to paint on. Because surfaces might have overlapping UVs, only
# one can be painted at a time. Needs to be set before `mesh_instance`.
var surface := 0
# The brush to use when painting. It specifies the parameters of the painting
# shader.
var brush : Brush setget set_brush
# If backfaces should be painted. This does'n paint both sides, and is only
# used to avoid having correct facing mesh and make the shader simpler.
var paint_through := false setget set_paint_through
# How large the resulting painted texture is.
var result_size := Vector2(1024, 1024) setget set_result_size

# True while the painter is active.
var _painting := false
# When the painter is busy, new requests store the position in `_next_position`
# instead of painting. After the painting is completed, a new paint stroke is
# started to `_next_position`.
var _next_position : Vector2
# The size of the viewport the user is painting in.
var _viewport_size : Vector2
# Cache of images loaded using `Image.load`.
var _cached_images : Dictionary = {}

const Brush = preload("res://addons/painter/brush.gd")
const MeshUtils = preload("res://addons/third_party/mesh_utils/mesh_utils.gd")

onready var paint_rect : ColorRect = $PaintViewport/PaintRect
onready var paint_material : ShaderMaterial = paint_rect.material
onready var paint_viewport : Viewport = $PaintViewport
onready var initial_texture_rect : TextureRect = $PaintViewport/InitialTextureRect
onready var view_to_texture_viewport : Viewport = $ViewToTextureViewport
onready var texture_to_view_viewport : Viewport = $TextureToViewViewport
onready var seams_viewport : Viewport = $SeamsViewport
onready var view_to_texture_camera : Camera = $ViewToTextureViewport/Camera
onready var texture_to_view_mesh_instance : MeshInstance = $TextureToViewViewport/MeshInstance
onready var view_to_texture_mesh_instance : MeshInstance = $ViewToTextureViewport/MeshInstance
onready var seams_rect : ColorRect = $SeamsViewport/SeamsRect
onready var seams_rect_material : ShaderMaterial = seams_rect.material

# The texture of the `Viewport` that generates the result.
# warning-ignore:unused_class_variable
onready var result : ViewportTexture = paint_viewport.get_texture()

func _ready() -> void:
	# Do this in code because it seems to not work when done in the editor.
	# Maybe related to https://github.com/godotengine/godot/pull/48794.
	seams_rect_material.set_shader_param("texture_to_view",
			texture_to_view_viewport.get_texture())
	paint_material.set_shader_param("seams", seams_viewport.get_texture())
	paint_material.set_shader_param("texture_to_view",
			texture_to_view_viewport.get_texture())
	(texture_to_view_mesh_instance.material_override as ShaderMaterial).\
			set_shader_param("view_to_texture",
			view_to_texture_viewport.get_texture())


# Sets the base texture that will be painted ontop of.
func set_initial_texture(texture : Texture) -> void:
	initial_texture_rect.texture = texture
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	paint_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	initial_texture_rect.texture = null


# Update the viewport if the size or camera changed.
func update_view(viewport : Viewport) -> void:
	_viewport_size = viewport.size
	
	var camera := viewport.get_camera()
	
	view_to_texture_viewport.size = 2.0 * viewport.size
	view_to_texture_camera.transform = camera.global_transform
	view_to_texture_camera.fov = camera.fov
	view_to_texture_camera.near = camera.near
	view_to_texture_camera.far = camera.far
	view_to_texture_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	
	yield(VisualServer, "frame_post_draw")
	
	var texture_to_view_material : ShaderMaterial = texture_to_view_mesh_instance.material_override
	texture_to_view_material.set_shader_param("model_transform", camera.global_transform.affine_inverse() * mesh_instance.global_transform)
	texture_to_view_material.set_shader_param("fovy_degrees", camera.fov)
	texture_to_view_material.set_shader_param("z_near", camera.near)
	texture_to_view_material.set_shader_param("z_far", camera.far)
	texture_to_view_material.set_shader_param("aspect", viewport.size.x / viewport.size.y)
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	
	if brush:
		paint_material.set_shader_param("brush_size", Vector2.ONE * brush.size / viewport.size)
	
	yield(VisualServer, "frame_post_draw")


# Paint onto `result` from `from` to `to` using the configured brush. Any calls
# to `paint` while the painter is busy will be recorded and the last stoke will
# be executed when the painter is done.
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


# Clear the result.
func clear() -> void:
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS
	paint_viewport.render_target_clear_mode = Viewport.UPDATE_ALWAYS
	yield(VisualServer, "frame_post_draw")
	paint_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER


func set_mesh_instance(to : MeshInstance) -> void:
	mesh_instance = to
	var mesh := MeshUtils.isolate_surface(mesh_instance.mesh, surface)
	texture_to_view_mesh_instance.mesh = mesh
	view_to_texture_mesh_instance.mesh = mesh
	texture_to_view_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")
	seams_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(VisualServer, "frame_post_draw")


func set_brush(to : Brush) -> void:
	brush = to
	
	var brush_texture : Texture
	var texture_mask : Texture
	
	if brush.texture:
		brush_texture = _load_image_texture(brush.texture)
	if brush.texture_mask:
		texture_mask = _load_image_texture(brush.texture_mask)
	
	paint_material.set_shader_param("brush_size",
			Vector2.ONE * brush.size / _viewport_size)
	paint_material.set_shader_param("brush_strength", brush.strength)
	paint_material.set_shader_param("brush_texture", brush_texture)
	paint_material.set_shader_param("brush_color", brush.color)
	paint_material.set_shader_param("pattern_scale", brush.pattern_scale)
	paint_material.set_shader_param("texture_angle", brush.texture_angle)
	paint_material.set_shader_param("stamp_mode", brush.stamp_mode)
	paint_material.set_shader_param("texture_mask", texture_mask)


func set_result_size(to : Vector2) -> void:
	result_size = to
	paint_viewport.size = to


func set_paint_through(to : bool) -> void:
	paint_through = to
	paint_material.set_shader_param("paint_through", paint_through)


func _load_image_texture(path : String) -> ImageTexture:
	if path in _cached_images:
		return _cached_images[path]
	var image := Image.new()
	image.load(path)
	var image_texture := ImageTexture.new()
	image_texture.create_from_image(image)
	_cached_images[path] = image_texture
	return image_texture
