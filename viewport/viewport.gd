extends ViewportContainer

"""
The 3D view that contains the loaded model with the generated material applied

Handles face selection and painting using the `SelectionUtils` and `Painter` addon.
The sun can be rotated by right clicking and dragging.
Responsible for selecting HDRIs and toggling HDRI visibility.
"""

export var light_sensitivity := 0.01

var selected_tool : int
var mesh : Mesh setget set_mesh
var result_size : Vector2
var current_surface := 0

var _last_painted_position : Vector2
var _cached_camera_transform : Transform
var _painting_layer : PaintTextureLayer
var _mesh_maps_generated := false

var _painters := {}
var _selection_utils := {}

const Brush = preload("res://main/brush.gd")
const SelectionUtils = preload("res://addons/selection_utils/selection_utils.gd")
const ProjectFile = preload("res://main/project_file.gd")
const Painter = preload("res://addons/painter/painter.gd")
const BrushAsset = preload("res://asset/assets/brush_asset.gd")
const Asset = preload("res://asset/assets/asset.gd")
const Model = preload("res://viewport/model.gd")
const PaintTextureLayer = preload("res://material/texture_layer/paint_texture_layer.gd")

onready var model : Model = $Viewport/Model
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport
onready var navigation_camera : Camera = $Viewport/NavigationCamera
onready var fps_label : Label = $FPSLabel
onready var half_resolution_button : CheckButton = $HalfResolutionButton

func _ready() -> void:
	navigation_camera.set_process_input(false)
	world_environment.environment = world_environment.environment.duplicate()
	if Settings.get_setting("enable_antialiasing"):
		viewport.fxaa = true
		viewport.msaa = Viewport.MSAA_2X


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
		directional_light.rotate_y(motion_ev.relative.x * light_sensitivity)
		if world_environment.environment.background_mode == Environment.BG_COLOR_SKY:
			world_environment.environment.background_sky_rotation_degrees.y =\
					directional_light.rotation_degrees.y


func _process(_delta : float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())


func _on_Main_mesh_changed(to : Mesh) -> void:
	set_mesh(to)


func _on_Main_current_layer_material_changed(_to : Reference, _id : int) -> void:
	if Settings.get_setting("generate_utility_maps") == "On Startup":
		update_mesh_maps()


func _on_Main_layer_materials_changed(to) -> void:
	model.layer_materials = to


func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1


func set_mesh(to):
	mesh = to
	model.mesh = mesh
	_painters.clear()
	_selection_utils.clear()


func get_layout_data() -> bool:
	return stretch_shrink == 2


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is PaintTextureLayer:
		if not _mesh_maps_generated:
			update_mesh_maps()
		_painting_layer = layer
		_load_paint_layer()
	else:
		_painting_layer = null


func _load_paint_layer() -> void:
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
		get_painter().brush = asset.data


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


func _on_Main_selected_tool_changed(to : int) -> void:
	selected_tool = to
	_load_paint_layer()


func _on_ResultsItemList_map_selected(map : String) -> void:
	model.isolated_map = "" if map == model.isolated_map else map


func _on_layout_changed(meta) -> void:
	if meta != null:
		half_resolution_button.pressed = meta


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


func _on_visibility_changed() -> void:
	if (get_parent() as CanvasItem).visible:
		_load_paint_layer()


func get_painter() -> Painter:
	if not current_surface in _painters:
		var painter : Painter = preload(\
				"res://addons/painter/painter.tscn").instance()
		add_child(painter)
		painter.surface = current_surface
		painter.mesh_instance = model
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
