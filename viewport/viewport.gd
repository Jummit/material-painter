extends ViewportContainer

"""
The 3D view that contains the loaded model with the generated material applied

Handles face selection and painting using the `SelectionUtils` and `Painter` addon.
The sun can be rotated by right clicking and dragging.
Responsible for selecting HDRIs and toggling HDRI visibility.
"""

var light_sensitivity := 0.01
var last_painted_position : Vector2
var cached_camera_transform : Transform

const Brush = preload("res://addons/painter/brush.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const AssetType = preload("res://asset_browser/asset_classes.gd").AssetType
const BrushAssetType = preload("res://asset_browser/asset_classes.gd").BrushAssetType
const SelectionUtils = preload("res://addons/selection_utils/selection_utils.gd")

onready var model : MeshInstance = $Viewport/Model
onready var layer_tree : Tree = $"../../../../../../LayerPanelContainer/Window/LayerTree"
onready var world_environment : WorldEnvironment = $Viewport/WorldEnvironment
onready var directional_light : DirectionalLight = $Viewport/DirectionalLight
onready var viewport : Viewport = $Viewport
onready var painter : Node = $Painter
onready var selection_utils : Node = $SelectionUtils
onready var navigation_camera : Camera = $Viewport/NavigationCamera

func _ready() -> void:
	if ProjectSettings.get_setting("application/config/initialize_painter"):
		painter.mesh_instance = model
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")
	navigation_camera.set_process_input(false)
	world_environment.environment = world_environment.environment.duplicate()


func _gui_input(event : InputEvent) -> void:
	navigation_camera._input(event)
	if layer_tree.get_selected_layer() is BitmapTextureLayer and ((event is\
			InputEventMouseButton and event.button_index == BUTTON_LEFT\
			and event.pressed) or (event is InputEventMouseMotion and\
			event.button_mask == BUTTON_LEFT)):
		if Globals.selected_tool == Globals.Tools.PAINT:
			paint(layer_tree.get_selected_layer(), event.position,
					event.position)
			last_painted_position = event.position
		else:
			select(layer_tree.get_selected_layer(),
					Globals.selected_tool,
					event.position)
	
	if not get_viewport().gui_is_dragging() and event is InputEventMouseMotion\
			and Input.is_mouse_button_pressed(BUTTON_LEFT) and\
			layer_tree.get_selected_layer() is BitmapTextureLayer\
			and Globals.selected_tool == Globals.Tools.PAINT:
		paint(layer_tree.get_selected_layer(), last_painted_position,
				event.position)
		last_painted_position = event.position
	
	if event is InputEventMouseButton and event.pressed and\
			event.button_mask == BUTTON_MASK_RIGHT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and\
			Input.is_mouse_button_pressed(BUTTON_RIGHT) and\
			event.button_mask == BUTTON_MASK_RIGHT:
		directional_light.rotate_y(event.relative.x * light_sensitivity)
		if world_environment.environment.background_mode == Environment.BG_COLOR_SKY:
			world_environment.environment.background_sky_rotation_degrees.y =\
					directional_light.rotation_degrees.y
	if event is InputEventMouseButton and not event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ViewMenuButton_hdri_selected(hdri : Texture) -> void:
	world_environment.environment.background_sky.panorama = hdri


func _on_ToolButtonContainer_tool_selected(tool_id : int) -> void:
	var bitmap_texture_layer : BitmapTextureLayer = layer_tree.get_selected_layer()
	if tool_id == Globals.Tools.PAINT:
		painter.set_initial_texture(bitmap_texture_layer.temp_texture)
		bitmap_texture_layer.temp_texture = painter.result


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	if texture_layer is BitmapTextureLayer:
		painter.clear()
		painter.set_initial_texture(texture_layer.temp_texture)


func _on_ToolSettingsPropertyPanel_brush_changed(brush : Brush) -> void:
	yield(self, "tree_entered")
	painter.brush = brush


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset.type is BrushAssetType:
		painter.brush = asset.data


func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1


func _on_Globals_mesh_changed(mesh : Mesh) -> void:
	var progress_dialog = ProgressDialogManager.create_task(
			"Generate Painter Maps", 1)
	mesh = _prepare_mesh(mesh)
	model.mesh = mesh
	progress_dialog.set_action("Generate Maps")
	yield(painter.set_mesh_instance(model), "completed")
	progress_dialog.complete_task()
	yield(get_tree(), "idle_frame")
	progress_dialog = ProgressDialogManager.create_task(
			"Generate Selection Maps", selection_utils.SelectionType.size())
	for selection_type in selection_utils._selection_types:
		progress_dialog.set_action(selection_utils.SelectionType.keys()[
				selection_type])
		var prepared_mesh = selection_utils._selection_types[selection_type].\
				prepare_mesh(mesh)
		if prepared_mesh is GDScriptFunctionState:
			prepared_mesh = yield(prepared_mesh, "completed")
		yield(get_tree(), "idle_frame")
		selection_utils._prepared_meshes[selection_type] = prepared_mesh
	progress_dialog.complete_task()


func _on_ResultsItemList_map_selected(map : String) -> void:
	model.isolated_map = "" if map == model.isolated_map else map


# perform a selection with the given `type` using `selection_utils`
func select(on_texture_layer : BitmapTextureLayer, type : int,
		position : Vector2) -> void:
	selection_utils.update_view(viewport)
	on_texture_layer.temp_texture = yield(selection_utils.add_selection(
			type, position, Globals.result_size,
			on_texture_layer.temp_texture), "completed")
	layer_tree.get_selected_layer().mark_dirty()
	Globals.editing_layer_material.update()


# perform a paintstroke from `from` to `to` using the `painter`
func paint(on_texture_layer : BitmapTextureLayer, from : Vector2,
		to : Vector2) -> void:
	var camera : Camera = viewport.get_camera()
	var camera_transform = camera.global_transform
	if camera_transform != cached_camera_transform:
		yield(painter.update_view(viewport), "completed")
	cached_camera_transform = camera_transform
	painter.paint(from / rect_size, to / rect_size)
	on_texture_layer.temp_texture = painter.result
	on_texture_layer.mark_dirty()
	Globals.editing_layer_material.update()


func _prepare_mesh(mesh : Mesh) -> Mesh:
	return mesh
