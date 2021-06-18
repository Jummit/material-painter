extends ViewportContainer

"""
The 3D view that contains the loaded model with the generated material applied

Handles face selection and painting using the `SelectionUtils` and `Painter` addon.
The sun can be rotated by right clicking and dragging.
Responsible for selecting HDRIs and toggling HDRI visibility.
"""

export var light_sensitivity := 0.1
export var is_2d := false

var selected_tool : int
var mesh : Mesh setget set_mesh
var original_mesh : Mesh
var result_size : Vector2
var current_surface := 0
var light_rotation := 0.0 setget set_light_rotation

var blur_amount := 0 setget set_blur_amount
var background_visible := false setget set_background_visible
var hdri : Image setget set_hdri

var _last_painted_position : Vector2
var _cached_camera_transform : Transform
var _painting_layer : PaintTextureLayer
var _mesh_maps_generated := false

var _painters := {}
var _selection_utils := {}

var RADIANCES := {
	"32": Sky.RADIANCE_SIZE_32,
	"64": Sky.RADIANCE_SIZE_64,
	"128": Sky.RADIANCE_SIZE_128,
	"256": Sky.RADIANCE_SIZE_256,
	"512": Sky.RADIANCE_SIZE_512,
	"1024": Sky.RADIANCE_SIZE_1024,
	"2048": Sky.RADIANCE_SIZE_2048,
}

const HdriAsset = preload("res://asset/assets/hdri_asset.gd")
const Brush = preload("res://main/brush.gd")
const SelectionUtils = preload("res://addons/selection_utils/selection_utils.gd")
const ProjectFile = preload("res://main/project_file.gd")
const Painter = preload("res://addons/painter/painter.gd")
const BrushAsset = preload("res://asset/assets/brush_asset.gd")
const Asset = preload("res://asset/assets/asset.gd")
const Model = preload("res://viewport/model.gd")
const PaintTextureLayer = preload("res://material/paint_texture_layer.gd")

onready var texture_rect : TextureRect = $Viewport/SkyViewport/TextureRect
onready var sky_viewport : Viewport = $Viewport/SkyViewport
onready var model : Model = $Viewport/Model
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport
onready var navigation_camera : NavigationCamera = $Viewport/NavigationCamera
onready var fps_label : Label = $FPSLabel
onready var half_resolution_button : CheckButton = $HalfResolutionButton

func _ready() -> void:
	navigation_camera.pan_only = is_2d
	navigation_camera.set_process_input(false)
#	world_environment.environment = world_environment.environment.duplicate()
	sky_viewport.get_texture().flags = Texture.FLAG_FILTER
# warning-ignore:unsafe_property_access
	world_environment.environment.background_sky.panorama = sky_viewport.get_texture()
	set_hdri(preload("res://viewport/cannon.hdr").get_data())


func _gui_input(event : InputEvent) -> void:
	navigation_camera._input(event)
	var button_ev := event as InputEventMouseButton
	var motion_ev := event as InputEventMouseMotion
	var from : Vector2
	var to : Vector2
	if not get_viewport().gui_is_dragging() and _painting_layer:
		if button_ev and button_ev.button_index == BUTTON_LEFT and button_ev.pressed:
			from = button_ev.position
			to = button_ev.position
		elif motion_ev and motion_ev.button_mask == BUTTON_LEFT:
			from = _last_painted_position
			to = motion_ev.position
	if from and to:
		if selected_tool == Constants.Tools.PAINT:
			paint(from, to)
			_last_painted_position = to
		else:
			select(selected_tool, to / stretch_shrink)
	
	if button_ev and button_ev.pressed and\
			button_ev.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif button_ev and not button_ev.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_last_painted_position = Vector2()
	if motion_ev and motion_ev.button_mask == BUTTON_MASK_RIGHT:
		self.light_rotation += motion_ev.relative.x * light_sensitivity


func _process(_delta : float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())


func set_light_rotation(to : float) -> void:
	light_rotation = to
	directional_light.rotation_degrees.y = light_rotation
	if world_environment.environment.background_mode == Environment.BG_COLOR_SKY:
		world_environment.environment.background_sky_rotation_degrees.y =\
				directional_light.rotation_degrees.y


func set_mesh(to):
	mesh = to
	model.mesh = mesh
	_painters.clear()
	_selection_utils.clear()


func set_background_visible(to) -> void:
	background_visible = to
	if background_visible:
		world_environment.environment.background_mode = Environment.BG_SKY
	else:
		world_environment.environment.background_mode = Environment.BG_COLOR_SKY


func set_hdri(to):
	if hdri == to:
		return
	hdri = to
	var texture := ImageTexture.new()
	texture.create_from_image(hdri)
	sky_viewport.size = hdri.get_size()
	texture_rect.texture = texture
	texture_rect.rect_size = hdri.get_size()
	sky_viewport.render_target_update_mode = Viewport.UPDATE_ONCE
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	# Update the radiance texture, as it's not done automatically.
	world_environment.environment.background_sky.radiance_size =\
			world_environment.environment.background_sky.radiance_size


func set_blur_amount(to):
	if blur_amount == to:
		return
	blur_amount = to
# warning-ignore:unsafe_method_access
	texture_rect.material.set_shader_param("strength", blur_amount)
	sky_viewport.render_target_update_mode = Viewport.UPDATE_ONCE


func get_layout_data() -> bool:
	return stretch_shrink == 2


func _on_Main_mesh_changed(to : Mesh) -> void:
	original_mesh = to
	set_mesh(uv_to_vertex_positions(to, 0) if is_2d else to)


func _on_Main_current_layer_material_changed(_to : Reference, id : int) -> void:
	if is_2d:
		set_mesh(uv_to_vertex_positions(original_mesh, id))
	if Settings.get_setting("generate_utility_maps") == "On Startup":
		update_mesh_maps()


func _on_Main_layer_materials_changed(to) -> void:
	model.layer_materials = to


func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1


func _on_DisplaySettingsWindow_changed(to : Dictionary) -> void:
	var env : Environment = world_environment.environment
	env.background_energy = to.exposure
	viewport.fxaa = to.antialiasing
	viewport.msaa = Viewport.MSAA_2X if to.antialiasing else Viewport.MSAA_DISABLED
	self.light_rotation = to.rotation
	directional_light.shadow_enabled = to.shadows
	if not is_2d:
		navigation_camera.projection = Camera.PROJECTION_PERSPECTIVE if\
				to.camera_mode == "Perspective" else Camera.PROJECTION_ORTHOGONAL
	if to.hdri:
		set_hdri(to.hdri.data)
	env.background_color = to.background_color
	var radiance : int = RADIANCES[to.radiance_size]
	if env.background_sky.radiance_size != radiance:
		env.background_sky.radiance_size = radiance
	set_background_visible(to.show_environment)
	set_blur_amount(to.blur)


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is PaintTextureLayer:
		if not _mesh_maps_generated:
			update_mesh_maps()
		_painting_layer = layer
		load_paint_layer()
	else:
		_painting_layer = null


func _on_ToolSettingsPropertyPanel_brush_changed(brush : Brush) -> void:
	if not get_painter():
		yield(self, "ready")
	var brushes := []
	for map in _painting_layer.enabled_maps:
		brushes.append(brush.get_brush(map))
	get_painter().brushes = brushes


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset is BrushAsset:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
		get_painter().brush = asset.data
	elif asset is HdriAsset:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
		set_hdri(asset.data)


func _on_Main_selected_tool_changed(to : int) -> void:
	selected_tool = to
	load_paint_layer()


func _on_ResultsItemList_map_selected(map : String) -> void:
	model.isolated_map = "" if map == model.isolated_map else map


func _on_layout_changed(meta) -> void:
	if meta != null:
		half_resolution_button.pressed = meta


func _on_visibility_changed() -> void:
	if (get_parent() as CanvasItem).visible:
		load_paint_layer()


# Perform a selection with the given `type` using selection utils.
func select(_type : int, _position : Vector2) -> void:
#	get_selection_utils().update_view(viewport)
#	_painting_layer.texture = yield(get_selection_utils().add_selection(
#			type, position, result_size,
#			_painting_layer.texture), "completed")
#	_painting_layer.mark_dirty()
## warning-ignore:unsafe_property_access
#	_painting_layer.get_layer_texture_in().parent.get_layer_material_in().update()
	pass


# Perform a paintstroke from `from` to `to` using the `painter`.
func paint(from : Vector2, to : Vector2) -> void:
	var painter := get_painter()
	painter.result_size = result_size
	var camera : Camera = viewport.get_camera()
	var camera_transform = camera.global_transform
	if camera_transform != _cached_camera_transform:
		yield(painter.update_view(viewport), "completed")
	_cached_camera_transform = camera_transform
	painter.paint(from / rect_size, to / rect_size)
	var channel := 0
	for map in _painting_layer.enabled_maps:
		_painting_layer.paint_textures[map] = painter.get_result(channel)
		channel += 1
	_painting_layer.mark_dirty()
# warning-ignore:unsafe_method_access
	_painting_layer.parent.get_layer_material_in()\
			.update()


func update_mesh_maps() -> void:
# warning-ignore:unsafe_method_access
	var progress_dialog = ProgressDialogManager.create_task(
			"Generate Painter Maps", 1)
	progress_dialog.set_action("Generate Maps")
	yield(get_painter().set_mesh_instance(model), "completed")
	progress_dialog.complete_task()
	yield(get_tree(), "idle_frame")
	var selection_utils := get_selection_utils()
# warning-ignore:unsafe_method_access
	progress_dialog = ProgressDialogManager.create_task(
			"Generate Selection Maps", selection_utils.SelectionType.size())
	for selection_type in selection_utils._selection_types:
		progress_dialog.set_action(selection_utils.SelectionType.keys()[
				selection_type])
		yield(get_tree(), "idle_frame")
		var prepared_mesh = selection_utils._selection_types[selection_type].\
				prepare_mesh(model.mesh, current_surface)
		if prepared_mesh is GDScriptFunctionState:
			prepared_mesh = yield(prepared_mesh, "completed")
		selection_utils._prepared_meshes[selection_type] = prepared_mesh
	progress_dialog.complete_task()
	_mesh_maps_generated = true


func load_paint_layer() -> void:
#	if not _painting_layer or selected_tool != Constants.Tools.PAINT or not is_visible_in_tree():
#		return
#	# Don't make this the initial texture if it's already the painter's texture.
#	if _painting_layer.texture == get_painter().paint_viewport.get_texture():
#		return
#	yield(get_painter().clear(), "completed")
#	yield(get_painter().set_initial_texture(_painting_layer.texture), "completed")
#	_painting_layer.texture = get_painter().result
#	_painting_layer.mark_dirty()
## warning-ignore:unsafe_property_access
#	_painting_layer.get_layer_texture_in().parent.get_layer_material_in().update()
	pass


func get_painter() -> Painter:
	if not current_surface in _painters:
		var painter : Painter = preload(\
				"res://addons/painter/painter.tscn").instance()
		add_child(painter)
		painter.surface = current_surface
		painter.mesh_instance = model
		painter.paint_through = is_2d
		_painters[current_surface] = painter
	return _painters[current_surface]


func get_selection_utils() -> SelectionUtils:
	if not current_surface in _selection_utils:
		var selection_utils : SelectionUtils = preload(\
				"res://addons/selection_utils/selection_utils.tscn").instance()
		add_child(selection_utils)
		selection_utils.set_mesh(mesh, current_surface)
		_selection_utils[current_surface] = selection_utils
	return _selection_utils[current_surface]


func can_drop_data(_position : Vector2, data) -> bool:
	return data is Asset and data is HdriAsset


func drop_data(_position : Vector2, data : HdriAsset) -> void:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
	set_hdri(data.data)


# warning-ignore:shadowed_variable
static func uv_to_vertex_positions(mesh : Mesh, surface : int) -> Mesh:
	var data_tool := MeshDataTool.new()
	var new_mesh := Mesh.new()
	for surface_num in mesh.get_surface_count():
		data_tool.create_from_surface(mesh, surface)
		for vertex in data_tool.get_vertex_count():
			if surface_num == surface:
				var uv := data_tool.get_vertex_uv(vertex)
				data_tool.set_vertex(vertex, Vector3(uv.x, 1.0 - uv.y, 0))
			else:
				# Kinda hacky: move all vertices of the unused surfaces to 0,0,0.
				data_tool.set_vertex(vertex, Vector3.ZERO)
		data_tool.commit_to_surface(new_mesh)
	return new_mesh
