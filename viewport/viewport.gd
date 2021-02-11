extends ViewportContainer

"""
The 3D view that contains the loaded model with the generated material applied

Handles face selection and painting using the `SelectionUtils` and `Painter` addon.
The sun can be rotated by right clicking and dragging.
Responsible for selecting HDRIs and toggling HDRI visibility.
"""

export var light_sensitivity := 0.01

var selected_tool : int
var mesh : Mesh
var result_size : Vector2

var _last_painted_position : Vector2
var _cached_camera_transform : Transform
var _painting_layer : BitmapTextureLayer
var _mesh_maps_generated := false

const Brush = preload("res://addons/painter/brush.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const AssetType = preload("res://asset_browser/asset_classes.gd").AssetType
const BrushAssetType = preload("res://asset_browser/asset_classes.gd").BrushAssetType
const SelectionUtils = preload("res://addons/selection_utils/selection_utils.gd")
const ProjectFile = preload("res://resources/project_file.gd")

onready var model : MeshInstance = $Viewport/Model
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport
onready var painter : Node = $Painter
onready var selection_utils : Node = $SelectionUtils
onready var navigation_camera : Camera = $Viewport/NavigationCamera
onready var fps_label : Label = $FPSLabel
onready var half_resolution_button : CheckButton = $HalfResolutionButton

func _ready() -> void:
	painter.mesh_instance = model
	navigation_camera.set_process_input(false)
	world_environment.environment = world_environment.environment.duplicate()


func _gui_input(event : InputEvent) -> void:
	navigation_camera._input(event)
	if not get_viewport().gui_is_dragging() and _painting_layer and ((event is\
			InputEventMouseButton and event.button_index == BUTTON_LEFT\
			and event.pressed) or (event is InputEventMouseMotion and\
			event.button_mask == BUTTON_LEFT)):
		if selected_tool == Constants.Tools.PAINT:
			paint(event.position, event.position)
			_last_painted_position = event.position
		else:
			select(selected_tool, event.position / stretch_shrink)
	
	if event is InputEventMouseButton and event.pressed and\
			event.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_RIGHT:
		directional_light.rotate_y(event.relative.x * light_sensitivity)
		if world_environment.environment.background_mode == Environment.BG_COLOR_SKY:
			world_environment.environment.background_sky_rotation_degrees.y =\
					directional_light.rotation_degrees.y
	if event is InputEventMouseButton and not event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(_delta : float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())


func _on_ViewMenuButton_hdri_selected(hdri : Texture) -> void:
	world_environment.environment.background_sky.panorama = hdri


func _on_Main_mesh_changed(to : Mesh) -> void:
	mesh = _prepare_mesh(to)
	model.mesh = mesh
	if Settings.get_setting("generate_utility_maps") == "On Startup":
		update_mesh_maps()
	

func _on_Main_layer_materials_changed(to) -> void:
	model.layer_materials = to


func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1


func get_layout_data() -> bool:
	return stretch_shrink == 2


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is BitmapTextureLayer:
		if not _mesh_maps_generated:
			update_mesh_maps()
		_painting_layer = layer
		_load_bitmap_layer()
	else:
		_painting_layer = null


func _load_bitmap_layer() -> void:
	if not _painting_layer or selected_tool != Constants.Tools.PAINT:
		return
	# don't make this the initial texture if it's already the painter's texture
	if _painting_layer.texture == painter.paint_viewport.get_texture():
		return
	painter.clear()
	painter.set_initial_texture(_painting_layer.texture)


func _on_ToolSettingsPropertyPanel_brush_changed(brush : Brush) -> void:
	if not painter:
		yield(self, "ready")
	painter.brush = brush


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset.type is BrushAssetType:
		painter.brush = asset.data


func update_mesh_maps() -> void:
	var progress_dialog = ProgressDialogManager.create_task(
			"Generate Painter Maps", 1)
	progress_dialog.set_action("Generate Maps")
	yield(painter.set_mesh_instance(model), "completed")
	progress_dialog.complete_task()
	yield(get_tree(), "idle_frame")
	progress_dialog = ProgressDialogManager.create_task(
			"Generate Selection Maps", selection_utils.SelectionType.size())
	for selection_type in selection_utils._selection_types:
		progress_dialog.set_action(selection_utils.SelectionType.keys()[
				selection_type])
		yield(get_tree(), "idle_frame")
		var prepared_mesh = selection_utils._selection_types[selection_type].\
				prepare_mesh(model.mesh)
		if prepared_mesh is GDScriptFunctionState:
			prepared_mesh = yield(prepared_mesh, "completed")
		selection_utils._prepared_meshes[selection_type] = prepared_mesh
	progress_dialog.complete_task()
	_mesh_maps_generated = true


func _on_Main_selected_tool_changed(to : int) -> void:
	selected_tool = to
	_load_bitmap_layer()


func _on_ResultsItemList_map_selected(map : String) -> void:
	model.isolated_map = "" if map == model.isolated_map else map


func _on_layout_changed(meta) -> void:
	if meta != null:
		half_resolution_button.pressed = meta


func _on_Main_result_size_changed(to) -> void:
	result_size = to


# perform a selection with the given `type` using `selection_utils`
func select(type : int, position : Vector2) -> void:
	selection_utils.update_view(viewport)
	_painting_layer.texture = yield(selection_utils.add_selection(
			type, position, result_size,
			_painting_layer.texture), "completed")
	_painting_layer.mark_dirty()
	_painting_layer.get_layer_texture_in().parent.get_layer_material_in().update()


# perform a paintstroke from `from` to `to` using the `painter`
func paint(from : Vector2, to : Vector2) -> void:
	painter.result_size = result_size
	var camera : Camera = viewport.get_camera()
	var camera_transform = camera.global_transform
	if camera_transform != _cached_camera_transform:
		yield(painter.update_view(viewport), "completed")
	_cached_camera_transform = camera_transform
	painter.paint(from / rect_size, to / rect_size)
	_painting_layer.texture = painter.result
	_painting_layer.mark_dirty()
	_painting_layer.get_layer_texture_in().parent.get_layer_material_in().update()


static func _prepare_mesh(to_prepare : Mesh) -> Mesh:
	return to_prepare


func _on_visibility_changed() -> void:
	if get_parent().visible:
		_load_bitmap_layer()
