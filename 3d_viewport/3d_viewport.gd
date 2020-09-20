extends ViewportContainer

signal painted(layer)

var sensitity := 0.01

const BitmapTextureLayer = preload("res://layers/texture_layers/bitmap_texture_layer.gd")
const MeshUtils = preload("res://utils/mesh_utils.gd")

onready var model : MeshInstance = $Viewport/Model
onready var layer_tree : Tree = $"../../../LayerTree/LayerTree"
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var color_skybox : MeshInstance = $Viewport/ColorSkybox
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight

func _gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if not layer_tree.get_selected():
			return
		var selected_texture_layer = layer_tree.get_selected_texture_layer()
		if not selected_texture_layer is BitmapTextureLayer:
			return
		var camera : Camera = $Viewport.get_camera()
		var camera_world_position := camera.project_position(event.position, 0.0)
		var clicked_world_position := camera.project_position(event.position, 1000.0)
		
		var selected_face := _get_nearest_intersecting_face(camera_world_position, clicked_world_position, model.mesh)
		if selected_face != -1:
			MeshUtils.paint_face(selected_texture_layer.image_data, selected_face, Color.white, model.mesh)
			emit_signal("painted", selected_texture_layer)
	if event is InputEventMouseButton and event.pressed and event.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_RIGHT) and event.button_mask == BUTTON_MASK_RIGHT:
		directional_light.rotate_y(event.relative.x * sensitity)
	if event is InputEventMouseButton and not event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ViewMenuButton_show_background_toggled() -> void:
	color_skybox.visible = not color_skybox.visible


func _on_ViewMenuButton_hdr_selected(hdr : Texture) -> void:
	world_environment.environment.background_sky.panorama = hdr


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
