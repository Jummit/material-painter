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

var current_file : SaveFile setget set_current_file
var current_layer_material : LayerMaterial setget set_current_layer_material
var selected_tool : int = Constants.Tools.PAINT
var undo_redo := UndoRedo.new()
var context : MaterialGenerationContext

onready var mesh_maps_generator : Node = $MeshMapsGenerator

# To avoid https://github.com/godotengine/godot/issues/36895, this is passed to
# `add_do_action` instead of null.
var NO_MASK := LayerTexture.new()

const MATERIALS_FOLDER := "user://materials"
const LAYOUTS_FOLDER := "user://layouts"

var file_menu_shortcuts := [
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_N),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_O),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_S),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_MASK_SHIFT + KEY_S),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_E),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_M),
	ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_Q),
]

enum FILE_MENU_ITEMS {
	NEW,
	OPEN,
	SAVE,
	SAVE_AS,
	EXPORT,
	LOAD_MESH,
	QUIT,
}

const ShortcutUtils = preload("res://utils/shortcut_utils.gd")
const SaveFile = preload("res://resources/project_file.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const TextureFolder = preload("res://resources/texture/texture_folder.gd")
const Brush = preload("res://addons/painter/brush.gd")
const ResourceUtils = preload("res://utils/resource_utils.gd")
const LayoutUtils = preload("res://addons/third_party/customizable_ui/layout_utils.gd")
const ObjParser = preload("res://addons/third_party/obj_parser/obj_parser.gd")
const JSONTextureLayer = preload("res://resources/texture/json_texture_layer.gd")
const MaterialGenerationContext = preload("res://material_generation_context.gd")
#const FileTextureLayer = preload("res://resources/texture/layers/file_texture_layer.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/FileMenuButton
onready var about_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/AboutMenuButton
onready var view_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/ViewMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_property_panel : Panel = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/PropertiesWindow/VBoxContainer/LayerPropertyPanel
onready var texture_map_buttons : GridContainer = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/PropertiesWindow/VBoxContainer/TextureMapButtons
onready var layer_tree : Tree = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/LayersWindow/LayerTree
onready var asset_browser : HBoxContainer = $VBoxContainer/Control/HBoxContainer/HSplitContainer/VBoxContainer/AssetBrowserWindow/AssetBrowser
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

func _ready() -> void:
	context = MaterialGenerationContext.new(layer_blend_viewport_manager,
			normal_map_generation_viewport, triplanar_texture_generator)
	
	ProgressDialogManager.theme = theme
	
	undo_redo.connect("version_changed", self, "_on_UndoRedo_version_changed")
	var popup := file_menu_button.get_popup()
	popup.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	about_menu_button.get_popup().connect("id_pressed", self,
			"_on_AboutMenuButton_id_pressed")
	for id in file_menu_shortcuts.size():
		popup.set_item_shortcut(id, file_menu_shortcuts[id])
	
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
			var to_save = file_dialog.get_meta("to_save")
			ResourceSaver.save(path, to_save)
			# ResourceSaver.FLAG_CHANGE_PATH doesn't work for some reason.
			to_save.resource_path = path
			if to_save is Brush:
				asset_browser.load_asset(path, asset_browser.ASSET_TYPES.BRUSH)
				asset_browser.update_asset_list()
			if to_save is SaveFile:
				for mat in to_save.layer_materials:
					mat.root_folder = current_file.resource_path.get_base_dir()
		FileDialog.MODE_OPEN_FILE:
			match path.get_extension():
				"res", "tres":
					set_current_file(ResourceLoader.load(path, "", true))
					for layer_mat in current_file.layer_materials:
						layer_mat.root_folder = current_file.resource_path.get_base_dir()
					load_mesh(current_file.model_path)
				"obj":
					load_mesh(path)


func _on_AddButton_pressed() -> void:
	var onto
	if layer_tree.is_folder(layer_tree.get_selected_layer()):
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
	var onto
	var selected_layer = layer_tree.get_selected_layer()
	if layer_tree.is_folder(layer_tree.get_selected_layer()):
		onto = selected_layer
	elif selected_layer is MaterialLayer and\
			layer_tree.get_selected_layer_texture(selected_layer):
		onto = layer_tree.get_selected_layer_texture(selected_layer)
	else:
		onto = current_layer_material
	
	var new_layer
	if onto is LayerMaterial or onto is MaterialFolder:
		new_layer = MaterialFolder.new()
	else:
		new_layer = TextureFolder.new()
	
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


func _on_AddLayerPopupMenu_layer_selected(layer : Resource) -> void:
	undo_redo.create_action("Add Texture Layer")
	var new_layer = layer.duplicate()
	var onto
	var selected_layer = layer_tree.get_selected_layer()
	if selected_layer is MaterialLayer or selected_layer is MaterialFolder:
		onto = layer_tree.get_selected_layer_texture(selected_layer)
	elif selected_layer is TextureFolder:
		onto = selected_layer
	else:
		onto = selected_layer.parent
	undo_redo.add_do_method(current_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_do_method(layer_tree, "reload")
	undo_redo.add_undo_method(current_layer_material, "delete_layer",
			new_layer)
	undo_redo.add_undo_method(layer_tree, "reload")
	undo_redo.commit_action()


func _on_MaterialLayerPopupMenu_layer_saved() -> void:
	var material_layer = layer_tree.get_selected_layer()
	var save_path := MATERIALS_FOLDER.plus_file(material_layer.name) + ".tres"
	ResourceSaver.save(save_path, material_layer)
	asset_browser.load_asset(save_path, asset_browser.ASSET_TYPES.MATERIAL)
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
	var new_layer = ResourceUtils.deep_copy_of_resource(
			layer_tree.get_selected_layer())
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
	if not current_file.resource_path:
		bake_error_dialog.popup()
		return
	
	var texture_dir : String = asset_browser.ASSET_TYPES.TEXTURE.\
			get_local_directory(current_file.resource_path)
	var dir := Directory.new()
	dir.make_dir_recursive(texture_dir)
	
	var progress_dialog = ProgressDialogManager.create_task("Bake Mesh Maps",
			mesh_maps_generator.BAKE_FUNCTIONS.size() * context.mesh.get_surface_count())
	
	for surface in context.mesh.get_surface_count():
		var mat_name : String = current_file.layer_materials[surface].resource_name
		for map in mesh_maps_generator.BAKE_FUNCTIONS:
			var file := texture_dir.plus_file(mat_name + map) + ".png"
			progress_dialog.set_action("%s: %s" % [mat_name, file])
			
			var result : ImageTexture = yield(mesh_maps_generator.generate_mesh_map(
					map, context.mesh, Vector2(1024, 1024), surface), "completed")
			
			result.get_data().save_png(file)
			asset_browser.load_asset(file, asset_browser.ASSET_TYPES.TEXTURE,
					"local")
	
	asset_browser.update_asset_list()
	progress_dialog.complete_task()


func _on_EditMenuButton_size_selected(size) -> void:
	context.result_size = size
	current_layer_material.update(true)


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
	get_tree().quit()


func _on_QuitConfirmationDialog_confirmed() -> void:
	if save_file():
		yield(file_dialog, "confirmed")
	current_file.save_bitmap_layers()
	# Todo: don't save twice.
	ResourceSaver.save(current_file.resource_path, current_file)
	get_tree().quit()


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
			file_dialog.filters = ["*.res,*.tres;Material Painter File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.popup_centered()
		FILE_MENU_ITEMS.SAVE:
			save_file()
		FILE_MENU_ITEMS.SAVE_AS:
			open_save_project_dialog()
		FILE_MENU_ITEMS.EXPORT:
			if current_file.resource_path:
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
			quit_confirmation_dialog.popup()


func _on_UndoRedo_version_changed() -> void:
	if undo_redo.get_current_action_name():
		print(undo_redo.get_current_action_name())


func export_materials() -> void:
	var progress_dialog = ProgressDialogManager.create_task("Export Textures",
			current_layer_material.results.size())
	yield(get_tree(), "idle_frame")
	for surface in current_file.layer_materials.size():
		var material_name := context.mesh.surface_get_material(
				surface).resource_name
		var export_folder := current_file.resource_path.get_base_dir()\
				.plus_file("export").plus_file(material_name)
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
	var progress_dialog = ProgressDialogManager.create_task("Load OBJ Model",
			stage_count)
	while true:
		progress_dialog.set_action("Stage %s / %s" % [
				interactive_loader.get_stage(), stage_count])
		yield(get_tree(), "idle_frame")
		for i in 20000:
			var new_mesh = interactive_loader.poll()
			if new_mesh:
				progress_dialog.complete_task()
				set_mesh(new_mesh)
				return

# Returns if the file wasn't saved and the user needs to specify where to
# save it.
func save_file() -> bool:
	if current_file.resource_path:
		ResourceSaver.save(current_file.resource_path,
				current_file)
		return false
	else:
		open_save_project_dialog()
		return true


func start_empty_project() -> void:
	set_current_file(SaveFile.new())
	set_mesh(preload("res://misc/cube.obj"))
	emit_signal("current_file_changed", current_file)


func open_save_project_dialog() -> void:
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.res,*.tres;Material Painter File"]
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
	var dir := Directory.new()
	dir.make_dir_recursive("user://layouts")
	var default := LAYOUTS_FOLDER.plus_file("default.json")
	# Wait for all windows to be ready.
	yield(get_tree(), "idle_frame")
	if not dir.file_exists(default):
		LayoutUtils.save_layout(root.get_child(0), default)
	else:
		LayoutUtils.load_layout(root, default)
	view_menu_button.update_layout_options()


func set_mesh(to) -> void:
	context.mesh = to
	current_file.model_path = to.resource_path
	current_file.layer_materials.resize(context.mesh.get_surface_count())
	for surface in context.mesh.get_surface_count():
		if not current_file.layer_materials[surface]:
			var new_material := LayerMaterial.new()
			if context.mesh.surface_get_material(surface):
				new_material.resource_name = context.mesh.surface_get_material(surface).resource_name
			current_file.layer_materials[surface] = new_material
	current_file.layer_materials.front().update(true)
	emit_signal("mesh_changed", context.mesh)
	emit_signal("layer_materials_changed", current_file.layer_materials)
	set_current_layer_material(current_file.layer_materials.front())


func set_current_layer_material(to) -> void:
	current_layer_material = to
	current_layer_material.context = context
	emit_signal("current_layer_material_changed", to,
			current_file.layer_materials.find(current_layer_material))


func set_current_file(save_file : SaveFile) -> void:
	current_file = save_file
	for layer_material in current_file.layer_materials:
		var result = layer_material.update(true)
		if result is GDScriptFunctionState:
			yield(result, "completed")
	context.result_size = current_file.result_size
	emit_signal("current_file_changed", current_file)


func _on_ToolButtonContainer_tool_selected(selected : int) -> void:
	selected_tool = selected
	emit_signal("selected_tool_changed", selected)
