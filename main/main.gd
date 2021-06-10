extends Control

"""
The main script of the Material Painter application

It handles most callbacks related to the application. Manages the menu bar,
saving and loading, switching layouts, undo and redo and some `LayerTree`
modification.
"""

signal current_file_changed(to)
signal layer_materials_changed(to)
signal current_layer_material_changed(to, id)
signal selected_tool_changed(to)
signal mesh_changed(to)
signal context_changed(to)

# The current project file.
var current_file : SaveFile setget set_current_file
# The currently editing `LayerMaterial`.
var current_layer_material : LayerMaterial setget set_current_layer_material
# The currently selected painting/selection tool.
var selected_tool : int = Constants.Tools.PAINT
var undo_redo := UndoRedo.new()
var context : MaterialGenerationContext

const MeshMapsGenerator = preload("res://main/mesh_maps_generator.gd")

onready var mesh_maps_generator : MeshMapsGenerator = $MeshMapsGenerator

# To avoid https://github.com/godotengine/godot/issues/36895, this is passed to
# `add_do_action` instead of null.
var NO_MASK := LayerTexture.new()

const LAYOUTS_FOLDER := "user://layouts"

enum FILE_MENU_ITEMS {
	NEW,
	OPEN,
	SAVE,
	SAVE_AS,
	EXPORT,
	LOAD_MESH,
	QUIT,
}

const SaveFile = preload("res://main/project_file.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const LayerMaterial = preload("res://material/layer_material.gd")
const TextureLayer = preload("res://material/texture_layer/texture_layer.gd")
const Brush = preload("res://addons/painter/brush.gd")
const LayoutUtils = preload("res://addons/third_party/customizable_ui/layout_utils.gd")
const ObjParser = preload("res://addons/third_party/obj_parser/obj_parser.gd")
const MaterialGenerationContext = preload("res://main/material_generation_context.gd")
const AssetStore = preload("res://asset/asset_store.gd")
const LayerTree = preload("res://layer_panel/layer_tree.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")
const AssetBrowser = preload("res://asset/asset_browser.gd")
const ViewMenuButton = preload("res://main/view_menu_button.gd")
const SmartMaterialAsset = preload("res://asset/assets/smart_material_asset.gd")
const LayerTexture = preload("res://material/layer_texture.gd")
const KeymapScreen = preload("res://addons/third_party/keymap_screen/keymap_screen.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/FileMenuButton
onready var edit_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/EditMenuButton
onready var about_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/AboutMenuButton
onready var view_menu_button : ViewMenuButton = $VBoxContainer/Panel/TopButtons/ViewMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_property_panel : Panel = $"VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/TabContainer2/PropertiesWindow/VBoxContainer/LayerPropertyPanel"
onready var texture_map_buttons : GridContainer = $"VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/TabContainer2/PropertiesWindow/VBoxContainer/TextureMapButtons"
onready var layer_tree : LayerTree = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/TabContainer/LayersWindow/VBoxContainer/LayerTree
onready var asset_browser : AssetBrowser = $VBoxContainer/Control/HBoxContainer/HSplitContainer/VBoxContainer/AssetBrowserWindow/AssetBrowser
onready var save_layout_dialog : ConfirmationDialog = $SaveLayoutDialog
onready var license_dialog : AcceptDialog = $LicenseDialog
onready var about_dialog : AcceptDialog = $AboutDialog
onready var export_error_dialog : AcceptDialog = $ExportErrorDialog
onready var bake_error_dialog : AcceptDialog = $BakeErrorDialog
onready var quit_confirmation_dialog : ConfirmationDialog = $QuitConfirmationDialog
onready var layout_name_edit : LineEdit = $SaveLayoutDialog/LayoutNameEdit
onready var root : Control = $VBoxContainer/Control
onready var triplanar_texture_generator : Viewport = $TriplanarTextureGenerator
onready var normal_map_generation_viewport : Viewport = $NormalMapGenerationViewport
onready var layer_blend_viewport_manager : Node = $LayerBlendViewportManager
onready var asset_store : AssetStore = $AssetStore
onready var keymap_screen : KeymapScreen = $SettingsDialog/TabContainer/KeymapScreen
onready var load_file_error_dialog : AcceptDialog = $LoadFileErrorDialog

const ShortcutUtils = preload("res://utils/shortcut_utils.gd")

func _ready() -> void:
	context = MaterialGenerationContext.new(layer_blend_viewport_manager,
			normal_map_generation_viewport, triplanar_texture_generator)
	
	asset_store.load_dir("res://assets")
	
# warning-ignore:unsafe_property_access
	ProgressDialogManager.theme = theme
	
	undo_redo.connect("version_changed", self, "_on_UndoRedo_version_changed")
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	about_menu_button.get_popup().connect("id_pressed", self,
			"_on_AboutMenuButton_id_pressed")
	
	keymap_screen.register_listeners({
		file_menu_button : [
			"new_file",
			"open_file",
			"save_file",
			"save_as",
			"export",
			"load_mesh",
			"quit",
		],
		edit_menu_button : [
			"bake_mesh_maps",
			"settings",
		],
		view_menu_button : [
			"view_results",
			"fullscreen",
			"update_icons"
		],
		about_menu_button : [
			"about",
			"github",
			"docs",
			"licenses",
			"issues"
		]
	})
	keymap_screen.load_keymap("user://keymap.json")
	initialise_layouts()
	start_empty_project()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("undo"):
		var action := undo_redo.get_current_action_name()
		if not undo_redo.undo():
			print("Nothing to undo.")
		elif action:
			print("Undo: " + action)
	elif event.is_action_pressed("redo"):
		if not undo_redo.redo():
			print("Nothing to redo.")
		else:
			print("Redo: " + undo_redo.get_current_action_name())


func _on_FileDialog_file_selected(path : String) -> void:
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			current_file.path = path
		FileDialog.MODE_OPEN_FILE:
			match path.get_extension():
				"mproject":
					var file := File.new()
					if file.open(path, File.READ) != OK:
						return
					var result = JSON.parse(file.get_as_text())
					if result.error:
						load_file_error_dialog.dialog_text = "Can't parse json: Content is corrupted.\n At line %s:\n%s" % [result.error_line, result.error_string]
						load_file_error_dialog.popup_centered()
						return
					var project := SaveFile.new(result.result)
					file.close()
					project.path = path
					set_current_file(project)
				"obj":
					load_mesh(path)


func _on_AddButton_pressed() -> void:
	var onto
	if layer_tree.get_selected_layer() is MaterialLayer and\
			layer_tree.get_selected_layer().is_folder:
		onto = layer_tree.get_selected_layer()
	else:
		onto = current_layer_material
	undo_redo.create_action("Add Material Layer")
	var new_layer := MaterialLayer.new()
	new_layer.parent = onto
	undo_redo.add_do_method(current_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(current_layer_material, "delete_layer",
			new_layer)
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_AddFolderButton_pressed() -> void:
	undo_redo.create_action("Add Folder Layer")
	var onto : Reference
	var selected_layer : Reference = layer_tree.get_selected_layer()
# warning-ignore:unsafe_property_access
	if selected_layer is MaterialLayer and\
			selected_layer.is_folder:
		onto = selected_layer
	elif selected_layer is MaterialLayer and\
			layer_tree.get_selected_layer_texture(selected_layer):
		onto = layer_tree.get_selected_layer_texture(selected_layer)
	else:
		onto = current_layer_material
	
	var new_layer := MaterialLayer.new()
	new_layer.name = "Untitled Folder"
	new_layer.is_folder = true
	
	undo_redo.add_do_method(current_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(current_layer_material, "delete_layer",
			new_layer)
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_DeleteButton_pressed() -> void:
	if not layer_tree.get_selected():
		return
	undo_redo.create_action("Delete Layer")
	var selected_layer = layer_tree.get_selected().get_meta("layer")
	undo_redo.add_do_method(current_layer_material, "delete_layer",
			selected_layer)
	undo_redo.add_do_method(layer_property_panel, "clear")
	undo_redo.add_do_method(texture_map_buttons, "hide")
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(current_layer_material, "add_layer",
			selected_layer, selected_layer.parent)
	undo_redo.add_undo_method(texture_map_buttons, "show")
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_AddLayerPopupMenu_layer_selected(layer : Reference) -> void:
	undo_redo.create_action("Add Texture Layer")
# warning-ignore:unsafe_method_access
	var new_layer : Reference = layer.duplicate()
	var onto
	var selected_layer = layer_tree.get_selected_layer()
	if selected_layer is MaterialLayer:
		onto = layer_tree.get_selected_layer_texture(selected_layer)
	else:
		onto = selected_layer.parent
	undo_redo.add_do_method(current_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_undo_method(current_layer_material, "delete_layer",
			new_layer)
	undo_redo.add_do_method(layer_tree, "expand_layer", selected_layer)
	undo_redo.add_undo_method(layer_tree, "collapse_layer", selected_layer)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_MaterialLayerPopupMenu_layer_saved() -> void:
	var material_layer : MaterialLayer = layer_tree.get_selected_layer()
	var dir := Directory.new()
	dir.make_dir_recursive("user://assets/smart_material")
	var save_path := "user://assets/smart_material".plus_file(material_layer.name) + ".json"
	var file := File.new()
	file.open(save_path, File.WRITE)
	file.store_string(to_json(material_layer.serialize()))
	file.close()
	asset_store.load_asset(save_path, SmartMaterialAsset)
	asset_browser.update_asset_list()


func _on_MaterialLayerPopupMenu_mask_added(mask : LayerTexture) -> void:
	do_change_mask_action("Add Mask", layer_tree.get_selected_layer(), mask)


func _on_MaterialLayerPopupMenu_mask_removed() -> void:
	do_change_mask_action("Remove Mask", layer_tree.get_selected_layer(),
			NO_MASK)


func _on_MaterialLayerPopupMenu_mask_pasted(mask : LayerTexture) -> void:
	do_change_mask_action("Paste Mask", layer_tree.get_selected_layer(), mask)


func _on_MaterialLayerPopupMenu_duplicated() -> void:
	undo_redo.create_action("Duplicate Layer")
	var new_layer = layer_tree.get_selected_layer().duplicate()
	undo_redo.add_do_method(current_layer_material, "add_layer",
			new_layer, current_layer_material)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(current_layer_material, "delete_layer",
			new_layer)
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_SaveButton_pressed() -> void:
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.current_dir = "user://brushes/"
	file_dialog.current_path = "user://brushes/"
	file_dialog.current_file = ""
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.filters = ["*.tres;Brush File"]
	# Todo: brush saving.
#	file_dialog.set_meta("to_save", painter.brush).
	file_dialog.popup_centered()


func _on_MaterialOptionButton_item_selected(index : int) -> void:
	set_current_layer_material(current_file.layer_materials[index])


func _on_EditMenuButton_bake_mesh_maps_pressed() -> void:
	if not current_file.path:
		bake_error_dialog.popup()
		return
	
	var texture_dir : String = current_file.path.get_base_dir().plus_file(
			"assets/texture")
	var dir := Directory.new()
	dir.make_dir_recursive(texture_dir)
	
# warning-ignore:unsafe_method_access
	var progress_dialog = ProgressDialogManager.create_task("Bake Mesh Maps",
			mesh_maps_generator.BAKE_FUNCTIONS.size() *\
			context.mesh.get_surface_count())
	
	for surface in context.mesh.get_surface_count():
		var mat_name := context.mesh.surface_get_material(surface).resource_name
		for map in mesh_maps_generator.BAKE_FUNCTIONS:
			var file := texture_dir.plus_file(mat_name + map) + ".png"
			progress_dialog.set_action("%s: %s" % [mat_name, file])
			
			var result : ImageTexture = yield(
					mesh_maps_generator.generate_mesh_map(map, context.mesh,
					Vector2(1024, 1024), surface), "completed")
			
			result.get_data().save_png(file)
			asset_store.load_asset(file, TextureAsset)
	
	asset_browser.update_asset_list()
	progress_dialog.complete_task()


func _on_EditMenuButton_size_selected(size) -> void:
	context.result_size = size
	current_layer_material.update()


func _on_LayoutNameEdit_text_entered(new_text : String) -> void:
	save_layout_dialog.hide()
	LayoutUtils.save_layout(root.get_child(0), LAYOUTS_FOLDER.plus_file(
			new_text + ".json"))
	view_menu_button.update_layout_options()


func _on_SaveLayoutDialog_confirmed() -> void:
	LayoutUtils.save_layout(root.get_child(0), LAYOUTS_FOLDER.plus_file(
			layout_name_edit.text + ".json"))
	view_menu_button.update_layout_options()


func _on_ViewMenuButton_layout_selected(layout : String) -> void:
	LayoutUtils.load_layout(root, LAYOUTS_FOLDER.plus_file(layout))


func _on_ViewMenuButton_save_layout_selected() -> void:
	save_layout_dialog.popup_centered()


func _on_QuitConfirmationDialog_custom_action(_action : String) -> void:
	do_quit()


func _on_QuitConfirmationDialog_confirmed() -> void:
	var result = request_save_file()
	if result is GDScriptFunctionState:
		yield(result, "completed")
	do_quit()


func do_quit():
	keymap_screen.save_keymap("user://keymap.json")
	get_tree().quit()


func request_save_file() -> void:
	if not current_file.path:
		open_save_project_dialog()
		yield(file_dialog, "file_selected")
	var file := File.new()
	file.open(current_file.path, File.WRITE)
	file.store_string(to_json(current_file.serialize()))
	file.close()


func _on_AboutMenuButton_id_pressed(id : int) -> void:
	match id:
		0:
			about_dialog.popup_centered()
		1:
			OS.shell_open("https://github.com/Jummit/material-painter")
		2:
			OS.shell_open("https://jummit.github.io/material-painter-docs")
		3:
			license_dialog.popup_centered()
		4:
			OS.shell_open("https://github.com/Jummit/material-painter/issues")


func _on_FileMenu_id_pressed(id : int) -> void:
	match id:
		FILE_MENU_ITEMS.NEW:
			start_empty_project()
		FILE_MENU_ITEMS.OPEN:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.filters = ["*.mproject;Material Painter File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.popup_centered()
		FILE_MENU_ITEMS.SAVE:
			request_save_file()
		FILE_MENU_ITEMS.SAVE_AS:
			open_save_project_dialog()
		FILE_MENU_ITEMS.EXPORT:
			if current_file.path:
				export_materials()
			else:
				export_error_dialog.popup_centered()
		FILE_MENU_ITEMS.LOAD_MESH:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.filters = ["*.obj;Object File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.popup_centered()
		FILE_MENU_ITEMS.QUIT:
			LayoutUtils.save_layout(root.get_child(0),
					LAYOUTS_FOLDER.plus_file("default.json"))
			quit_confirmation_dialog.popup()


func _on_UndoRedo_version_changed() -> void:
	if undo_redo.get_current_action_name():
		print(undo_redo.get_current_action_name())


func export_materials() -> void:
# warning-ignore:unsafe_method_access
	var progress_dialog = ProgressDialogManager.create_task("Export Textures",
			current_layer_material.results.size())
	yield(get_tree(), "idle_frame")
	for surface in current_file.layer_materials.size():
		var material_name := context.mesh.surface_get_material(
				surface).resource_name
		var export_folder := current_file.path.get_base_dir().plus_file("export")\
				.plus_file(material_name)
		var dir := Directory.new()
		dir.make_dir_recursive(export_folder)
		var results : Dictionary = current_file.layer_materials[surface].results
		for type in results:
			progress_dialog.set_action("%s of %s" % [type, material_name])
			var result_data : Image = results[type].get_data()
			result_data.save_png(export_folder.plus_file(type) + ".png")
			yield(get_tree(), "idle_frame")
	progress_dialog.complete_task()


func set_mask(layer, mask : LayerTexture) -> void:
	if mask == NO_MASK:
		layer.mask = null
	else:
		layer.mask = mask
		mask.parent = layer
		mask.mark_dirty()
	layer.mark_dirty()
	current_layer_material.update()


func load_mesh(path : String) -> void:
	var interactive_loader := ObjParser.parse_obj_interactive(path)
	var stage_count := int(interactive_loader.get_stage_count() / 20000.0)
# warning-ignore:unsafe_method_access
	var progress_dialog = ProgressDialogManager.create_task("Load OBJ Model",
			stage_count)
	while true:
		progress_dialog.set_action("Stage %s / %s" % [
				interactive_loader.get_stage(), stage_count])
		yield(get_tree(), "idle_frame")
		for i in 20000:
			var new_mesh = interactive_loader.poll()
			if not new_mesh:
				continue
			progress_dialog.complete_task()
			context.mesh = new_mesh
			current_file.model_path = path
			for surface in context.mesh.get_surface_count():
				if current_file.layer_materials.size() <= surface:
					current_file.layer_materials.append(LayerMaterial.new())
			current_file.layer_materials.front().update()
			emit_signal("mesh_changed", context.mesh)
			emit_signal("layer_materials_changed", current_file.layer_materials)
			set_current_layer_material(current_file.layer_materials.front())
			return


func start_empty_project() -> void:
	set_current_file(SaveFile.new({
		model_path = "res://misc/cube.obj"
	}))


func open_save_project_dialog() -> void:
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.mproject;Material Painter File"]
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.current_file = ""
	file_dialog.set_meta("to_save", current_file)
	file_dialog.popup_centered()


func do_change_mask_action(action_name : String, layer, mask : LayerTexture) -> void:
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(self, "set_mask", layer, mask)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(self, "set_mask", layer, layer.mask)
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func initialise_layouts() -> void:
	# Wait for all windows to be ready.
	yield(get_tree(), "idle_frame")
	var dir := Directory.new()
	dir.make_dir_recursive("user://layouts")
	var default := LAYOUTS_FOLDER.plus_file("default.json")
	if not dir.file_exists(default):
		LayoutUtils.save_layout(root.get_child(0), default)
	else:
		LayoutUtils.load_layout(root, default)
	view_menu_button.update_layout_options()


func set_current_file(save_file : SaveFile) -> void:
	current_file = save_file
	context.result_size = current_file.result_size
	for layer_material in current_file.layer_materials:
		layer_material.context = context
		var result = layer_material.update()
		if result is GDScriptFunctionState:
			yield(result, "completed")
	var result = load_mesh(current_file.model_path)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	set_current_layer_material(current_file.layer_materials.front())
	emit_signal("context_changed", context)
	emit_signal("current_file_changed", current_file)


func set_current_layer_material(to) -> void:
	current_layer_material = to
	current_layer_material.context = context
	emit_signal("current_layer_material_changed", to,
			current_file.layer_materials.find(current_layer_material))


func _on_ToolButtonContainer_tool_selected(selected : int) -> void:
	selected_tool = selected
	emit_signal("selected_tool_changed", selected)
