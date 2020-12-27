extends ViewportContainer

"""
The 3D view that contains a model with the generated material applied

Handles face selection and painting using the `Painter` addon.
"""

signal painted(layer)

var sensitity := 0.01
var last_painted_position : Vector2
var cached_camera_transform : Transform

const Brush = preload("res://addons/painter/brush.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const MeshUtils = preload("res://utils/mesh_utils.gd")
const Asset = preload("res://main/asset_browser.gd").Asset
const BrushAssetType = preload("res://main/asset_browser.gd").BrushAssetType

onready var model : MeshInstance = $Viewport/Model
onready var layer_tree : Tree = $"../../../../../../LayerPanelContainer/Window/LayerTree"
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var color_skybox : MeshInstance = $Viewport/RotatingCamera/ColorSkybox
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport
onready var painter : Node = $Painter

func _ready() -> void:
	if ProjectSettings.get_setting("application/config/initialize_painter"):
		painter.mesh_instance = model
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")


func _on_Globals_mesh_changed(_mesh : Mesh) -> void:
	painter.mesh_instance = model


func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			if _can_paint_with_tool(Globals.Tools.TRIANGLE):
				var camera : Camera = $Viewport.get_camera()
				var camera_world_position := camera.project_position(
						event.position, 0.0)
				var clicked_world_position := camera.project_position(
						event.position, 1000.0)
				var selected_texture_layer : BitmapTextureLayer = layer_tree.get_selected_layer()
				var selected_face := _get_nearest_intersecting_face(
						camera_world_position, clicked_world_position,
						model.mesh, Input.is_key_pressed(KEY_CONTROL))
				if selected_face != -1:
					MeshUtils.paint_face(
							selected_texture_layer.image_data,
							selected_face, Color.white, model.mesh)
					emit_signal("painted", selected_texture_layer)
			elif _can_paint_with_tool(Globals.Tools.PAINT):
				_paint(layer_tree.get_selected_layer(), event.position,
						event.position)
				last_painted_position = event.position
		
		if not event.pressed and Globals.selected_tool == Globals.Tools.PAINT:
			var selected_layer = layer_tree.get_selected_layer()
			if selected_layer is BitmapTextureLayer:
				selected_layer.image_data = selected_layer.temp_texture.get_data()
				selected_layer.temp_texture = null
	
	if not get_viewport().gui_is_dragging() and event is InputEventMouseMotion\
			and Input.is_mouse_button_pressed(BUTTON_LEFT) and\
			_can_paint_with_tool(Globals.Tools.PAINT):
		_paint(layer_tree.get_selected_layer(), last_painted_position,
				event.position)
		last_painted_position = event.position
	
	if event is InputEventMouseButton and event.pressed and\
			event.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and\
			Input.is_mouse_button_pressed(BUTTON_RIGHT) and\
			event.button_mask == BUTTON_MASK_RIGHT:
		directional_light.rotate_y(event.relative.x * sensitity)
	if event is InputEventMouseButton and not event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ViewMenuButton_show_background_toggled() -> void:
	color_skybox.visible = not color_skybox.visible


func _on_ViewMenuButton_hdri_selected(hdri : Texture) -> void:
	world_environment.environment.background_sky.panorama = hdri


func _on_ToolButtonContainer_tool_selected(tool_id : int):
	var bitmap_texture_layer : BitmapTextureLayer = layer_tree.get_selected_layer()
	if tool_id == Globals.Tools.PAINT:
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(bitmap_texture_layer.image_data)
		painter.set_initial_texture(image_texture)
		bitmap_texture_layer.temp_texture = painter.result
	else:
		bitmap_texture_layer.image_data = painter.result.get_data()
		bitmap_texture_layer.temp_texture = null


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	if texture_layer is BitmapTextureLayer:
		painter.clear()
		var texture := ImageTexture.new()
		texture.create_from_image(texture_layer.image_data)
		painter.set_initial_texture(texture)


func _on_ToolSettingsPropertyPanel_brush_changed(brush : Brush) -> void:
	yield(self, "tree_entered")
	painter.brush = brush


func _get_nearest_intersecting_face(start : Vector3, direction : Vector3,
		mesh : Mesh, fast := false) -> int:
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
			if fast:
				return face
			var distance : float = collision_point.distance_to(start)
			if distance < nearest_distance:
				nearest_face = face
				nearest_distance = distance
	return nearest_face


func _can_paint_with_tool(tool_id : int) -> bool:
	return layer_tree.get_selected_layer() is BitmapTextureLayer\
			and Globals.selected_tool == tool_id


func _paint(on_texture_layer : BitmapTextureLayer, from : Vector2,
		to : Vector2) -> void:
	var camera : Camera = viewport.get_camera()
	var camera_transform = camera.global_transform
	if camera_transform != cached_camera_transform:
		yield(painter.update_view(viewport), "completed")
	cached_camera_transform = camera_transform
	painter.paint(from / rect_size, to / rect_size)
	on_texture_layer.temp_texture = painter.result
	emit_signal("painted", on_texture_layer)


func _on_AssetBrowser_asset_activated(asset):
	if asset.type is BrushAssetType:
		painter.brush = asset.data
