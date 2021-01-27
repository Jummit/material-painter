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
var painting_layer : BitmapTextureLayer
var mesh_maps_generated := false

const Brush = preload("res://addons/painter/brush.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const AssetType = preload("res://asset_browser/asset_classes.gd").AssetType
const BrushAssetType = preload("res://asset_browser/asset_classes.gd").BrushAssetType
const SelectionUtils = preload("res://addons/selection_utils/selection_utils.gd")

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
	Globals.connect("mesh_changed", self, "_on_Globals_mesh_changed")
	Globals.connect("tool_changed", self, "_on_Globals_tool_changed")
	navigation_camera.set_process_input(false)
	world_environment.environment = world_environment.environment.duplicate()


func _gui_input(event : InputEvent) -> void:
	navigation_camera._input(event)
	if not get_viewport().gui_is_dragging() and painting_layer and ((event is\
			InputEventMouseButton and event.button_index == BUTTON_LEFT\
			and event.pressed) or (event is InputEventMouseMotion and\
			event.button_mask == BUTTON_LEFT)):
		if Globals.selected_tool == Globals.Tools.PAINT:
			paint(painting_layer, event.position, event.position)
			last_painted_position = event.position
		else:
			select(painting_layer, Globals.selected_tool,
					event.position / stretch_shrink)
	
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


func _on_HalfResolutionButton_toggled(button_pressed : bool) -> void:
	stretch_shrink = 2 if button_pressed else 1
	get_parent().set_meta("layout", button_pressed)


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is BitmapTextureLayer:
		if not mesh_maps_generated:
			update_mesh_maps()
		painting_layer = layer
		_load_bitmap_layer()
	else:
		painting_layer = null


func _on_Globals_tool_changed() -> void:
	_load_bitmap_layer()


func _load_bitmap_layer() -> void:
	if not painting_layer or Globals.selected_tool != Globals.Tools.PAINT:
		return
	# don't make this the initial texture if it's already the painter's texture
	if painting_layer.texture is ViewportTexture and\
			painting_layer.texture == painter.paint_viewport.get_texture():
		return
	painter.clear()
	painter.set_initial_texture(painting_layer.texture)


func _on_ToolSettingsPropertyPanel_brush_changed(brush : Brush) -> void:
	if not is_inside_tree():
		yield(self, "tree_entered")
	painter.brush = brush


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset.type is BrushAssetType:
		painter.brush = asset.data


func _on_Globals_mesh_changed(_mesh : Mesh) -> void:
	var mesh := _prepare_mesh(Globals.mesh)
	model.mesh = mesh
	if Settings.get_setting("generate_utility_maps") == "On Startup":
		update_mesh_maps()


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
	mesh_maps_generated = true


func _on_ResultsItemList_map_selected(map : String) -> void:
	model.isolated_map = "" if map == model.isolated_map else map


func _on_layout_changed() -> void:
	if get_parent().has_meta("layout"):
		var meta : bool = get_parent().get_meta("layout")
		half_resolution_button.pressed = meta


# perform a selection with the given `type` using `selection_utils`
func select(on_texture_layer : BitmapTextureLayer, type : int,
		position : Vector2) -> void:
	selection_utils.update_view(viewport)
	on_texture_layer.texture = yield(selection_utils.add_selection(
			type, position, Globals.result_size,
			on_texture_layer.texture), "completed")
	painting_layer.mark_dirty()
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
	on_texture_layer.texture = painter.result
	on_texture_layer.mark_dirty()
	Globals.editing_layer_material.update()


func _prepare_mesh(mesh : Mesh) -> Mesh:
	return mesh


func _on_visibility_changed() -> void:
	if get_parent().visible:
		_load_bitmap_layer()
