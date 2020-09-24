extends ViewportContainer

signal painted(layer)

var sensitity := 0.01
var last_painted_position : Vector2
var cashed_camera_transform : Transform

const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")
const MeshUtils = preload("res://utils/mesh_utils.gd")

onready var model : MeshInstance = $Viewport/Model
onready var layer_tree : Tree = $"../../../../LayerPanelContainer/LayerTree"
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var color_skybox : MeshInstance = $Viewport/ColorSkybox
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport

onready var seams : TextureRect = $HBoxContainer/Seams
onready var texture_to_view : TextureRect = $HBoxContainer/TextureToView
onready var view_to_texture : TextureRect = $HBoxContainer/ViewToTexture
onready var paint_result : TextureRect = $HBoxContainer/PaintResult

onready var painter : Node = $Painter

func _ready() -> void:
	painter.mesh_instance = model
	var utility_textures : Dictionary = painter.get_textures()
	view_to_texture.texture = utility_textures.view_to_texture
	texture_to_view.texture = utility_textures.texture_to_view
	seams.texture = utility_textures.seams
	paint_result.texture = painter.result


func _gui_input(event : InputEvent) -> void:
#	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
#		if not layer_tree.get_selected():
#			return
#		var selected_texture_layer = layer_tree.get_selected_texture_layer()
#		if not selected_texture_layer is BitmapTextureLayer:
#			return
#		var camera : Camera = $Viewport.get_camera()
#		var camera_world_position := camera.project_position(event.position, 0.0)
#		var clicked_world_position := camera.project_position(event.position, 1000.0)
#
#		var selected_face := _get_nearest_intersecting_face(camera_world_position, clicked_world_position, model.mesh)
#		if selected_face != -1:
#			MeshUtils.paint_face(selected_texture_layer.image_data, selected_face, Color.white, model.mesh)
#			emit_signal("painted", selected_texture_layer)
	if event is InputEventMouseButton and event.pressed and event.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_RIGHT) and event.button_mask == BUTTON_MASK_RIGHT:
		directional_light.rotate_y(event.relative.x * sensitity)
	if event is InputEventMouseButton and not event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if layer_tree.get_selected() and layer_tree.get_selected_texture_layer() is BitmapTextureLayer:
			_paint(layer_tree.get_selected_texture_layer(), event.position, event.position)
			last_painted_position = event.position
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_LEFT):
		if layer_tree.get_selected() and layer_tree.get_selected_texture_layer() is BitmapTextureLayer:
			_paint(layer_tree.get_selected_texture_layer(), last_painted_position, event.position)
			last_painted_position = event.position


func _on_ViewMenuButton_show_background_toggled() -> void:
	color_skybox.visible = not color_skybox.visible


func _on_ViewMenuButton_hdr_selected(hdr : Texture) -> void:
	world_environment.environment.background_sky.panorama = hdr


func _on_Model_mesh_changed() -> void:
	painter.mesh_instance = model


func _get_nearest_intersecting_face(start : Vector3, direction : Vector3, mesh : Mesh) -> int:
	var mesh_tool := MeshDataTool.new()
	mesh_tool.create_from_surface(mesh, 0)
	
	var nearest_face := -1
	var nearest_distance := INF
	for face in mesh_tool.get_face_count():
		var triangle := Basis(
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 0)),
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 1)),
				mesh_tool.get_vertex(mesh_tool.get_face_vertex(face, 2)))
		var collision_point = Geometry.ray_intersects_triangle(
				start, direction, triangle.x, triangle.y, triangle.z)
		if collision_point:
			var distance : float = collision_point.distance_to(start)
			if distance < nearest_distance:
				nearest_face = face
				nearest_distance = distance
	return nearest_face


func _paint(on_texture_layer : BitmapTextureLayer, from : Vector2, to : Vector2) -> void:
	var camera : Camera = viewport.get_camera()
	var camera_transform = camera.global_transform
	if camera_transform != cashed_camera_transform:
		yield(painter.update_view(viewport), "completed")
	cashed_camera_transform = camera_transform
	painter.paint(from / rect_size, to / rect_size)
	on_texture_layer.temp_texture = painter.result
	emit_signal("painted", on_texture_layer)
