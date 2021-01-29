extends Control

"""
The main script of the Material Painter application

It handles most callbacks related to the application. Manages the menu bar,
saving and loading, switching layouts, undo and redo and some `LayerTree`
modification.
"""

var _mesh_maps_generator = preload("res://main/mesh_maps_generator.gd").new()
var undo_redo := Globals.undo_redo

# to avoid https://github.com/godotengine/godot/issues/36895,
# this is passed to add_do_action instead of null
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
const SaveFile = preload("res://resources/save_file.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")
const LayerMaterial = preload("res://resources/material/layer_material.gd")
const MaterialFolder = preload("res://resources/material/material_folder.gd")
const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const TextureLayer = preload("res://resources/texture/texture_layer.gd")
const TextureFolder = preload("res://resources/texture/texture_folder.gd")
const Brush = preload("res://addons/painter/brush.gd")
const ResourceUtils = preload("res://utils/resource_utils.gd")
const LayoutUtils = preload("res://addons/customizable_ui/layout_utils.gd")
const ObjParser = preload("res://addons/obj_parser/obj_parser.gd")
const JSONTextureLayer = preload("res://resources/texture/json_texture_layer.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/FileMenuButton
onready var about_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/AboutMenuButton
onready var view_menu_button : MenuButton = $VBoxContainer/Panel/TopButtons/ViewMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_property_panel : Panel = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/PropertiesWindow/VBoxContainer/LayerPropertyPanel
onready var texture_map_buttons : GridContainer = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/PropertiesWindow/VBoxContainer/TextureMapButtons
onready var layer_tree : Tree = $VBoxContainer/Control/HBoxContainer/HSplitContainer/LayerPanelContainer/LayersWindow/LayerTree
onready var painter : Node = $"VBoxContainer/Control/HBoxContainer/HSplitContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewportWindow/3DViewport/Painter"
onready var asset_browser : HBoxContainer = $VBoxContainer/Control/HBoxContainer/HSplitContainer/VBoxContainer/AssetBrowserWindow/AssetBrowser
onready var save_layout_dialog : ConfirmationDialog = $SaveLayoutDialog
onready var license_dialog : AcceptDialog = $LicenseDialog
onready var about_dialog : AcceptDialog = $AboutDialog
onready var export_error_dialog : AcceptDialog = $ExportErrorDialog
onready var quit_confirmation_dialog : ConfirmationDialog = $QuitConfirmationDialog
onready var layout_name_edit : LineEdit = $SaveLayoutDialog/LayoutNameEdit
onready var root : Control = $VBoxContainer/Control

func _ready() -> void:
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
			if to_save is SaveFile:
				to_save.pre_save()
			ResourceSaver.save(path, to_save)
			# ResourceSaver.FLAG_CHANGE_PATH doesn't work for some reason
			to_save.resource_path = path
			if to_save is Brush:
				asset_browser.load_asset(path, asset_browser.ASSET_TYPES.BRUSH)
				asset_browser.update_asset_list()
		FileDialog.MODE_OPEN_FILE:
			match path.get_extension():
				"res", "tres":
					Globals.current_file = ResourceLoader.load(path, "", true)
					load_mesh(Globals.current_file.model_path)
				"obj":
					load_mesh(path)


func _on_AddButton_pressed() -> void:
	var onto
	if layer_tree.is_folder(layer_tree.get_selected_layer()):
		onto = layer_tree.get_selected_layer()
	else:
		onto = Globals.editing_layer_material
	undo_redo.create_action("Add Material Layer")
	var new_layer := MaterialLayer.new()
	new_layer.parent = onto
	undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_undo_method(Globals.editing_layer_material, "delete_layer",
			new_layer)
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
		onto = Globals.editing_layer_material
	
	var new_layer
	if onto is LayerMaterial or onto is MaterialFolder:
		new_layer = MaterialFolder.new()
	else:
		new_layer = TextureFolder.new()
	
	undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_undo_method(Globals.editing_layer_material, "delete_layer",
			new_layer)
	undo_redo.commit_action()


func _on_DeleteButton_pressed() -> void:
	if layer_tree.get_selected():
		undo_redo.create_action("Delete Layer")
		var selected_layer = layer_tree.get_selected().get_meta("layer")
		undo_redo.add_do_method(Globals.editing_layer_material, "delete_layer",
				selected_layer)
		undo_redo.add_do_method(layer_property_panel, "clear")
		undo_redo.add_do_method(texture_map_buttons, "hide")
		undo_redo.add_undo_method(Globals.editing_layer_material, "add_layer",
				selected_layer, selected_layer.parent)
		undo_redo.add_undo_method(texture_map_buttons, "show")
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
	undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
			new_layer, onto)
	undo_redo.add_undo_method(Globals.editing_layer_material, "delete_layer",
			new_layer)
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
	undo_redo.add_do_method(Globals.editing_layer_material, "add_layer",
			new_layer, Globals.editing_layer_material)
	undo_redo.add_undo_method(Globals.editing_layer_material, "delete_layer",
			new_layer)
	undo_redo.commit_action()


func _on_SaveButton_pressed() -> void:
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.current_dir = "user://brushes/"
	file_dialog.current_path = "user://brushes/"
	file_dialog.current_file = ""
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.filters = ["*.tres;Brush File"]
	file_dialog.set_meta("to_save", painter.brush)
	file_dialog.popup_centered()


func _on_MaterialOptionButton_item_selected(index : int) -> void:
	Globals.editing_layer_material = Globals.current_file.layer_materials[index]


func _on_EditMenuButton_bake_mesh_maps_pressed() -> void:
	var texture_dir : String = asset_browser.ASSET_TYPES.TEXTURE.\
			get_local_directory(Globals.current_file.resource_path)
	var dir := Directory.new()
	dir.make_dir_recursive(texture_dir)
	var progress_dialog = ProgressDialogManager.create_task("Bake Mesh Maps",
			_mesh_maps_generator.MESH_MAP_GENERATORS.size())
	
	for generator in _mesh_maps_generator.MESH_MAP_GENERATORS:
		var result : Texture = yield(generator._generate_map(Globals.mesh, Vector2(1024, 1024)),
				"completed")
		var file := texture_dir.plus_file(generator.name) + ".png"
		progress_dialog.set_action(file)
		result.get_data().save_png(file)
		var asset = asset_browser.load_asset(file,
				asset_browser.ASSET_TYPES.TEXTURE)
		asset_browser._add_asset_to_tag(asset, "local")
		if asset is GDScriptFunctionState:
			asset = yield(asset, "completed")
		asset_browser.assets.append(asset)
		yield(get_tree(), "idle_frame")
	asset_browser.update_asset_list()
	progress_dialog.complete_task()


func _on_EditMenuButton_size_selected(size) -> void:
	Globals.result_size = size
	Globals.editing_layer_material.update(true)


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
			if Globals.current_file.resource_path:
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
			Globals.editing_layer_material.results.size())
	yield(get_tree(), "idle_frame")
	for surface in Globals.current_file.layer_materials.size():
		var material_name := Globals.mesh.surface_get_material(
				surface).resource_name
		var export_folder := Globals.current_file.resource_path.get_base_dir()\
				.plus_file("export").plus_file(material_name)
		var dir := Directory.new()
		dir.make_dir_recursive(export_folder)
		var results : Dictionary = Globals.current_file.layer_materials[surface].results
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
	Globals.editing_layer_material.update()


func load_mesh(path : String) -> void:
	var interactive_loader := ObjParser.parse_obj_interactive(path)
	var stage_count := interactive_loader.get_stage_count()
	var progress_dialog = ProgressDialogManager.create_task("Load OBJ Model",
			stage_count)
	while true:
		progress_dialog.set_action("Stage %s / %s" % [
				interactive_loader.get_stage(), stage_count],
				interactive_loader.get_stage())
		yield(get_tree(), "idle_frame")
		for i in 20000:
			var mesh = interactive_loader.poll()
			if mesh:
				progress_dialog.complete_task()
				Globals.mesh = mesh
				return


func save_file() -> bool:
	if not Globals.current_file.resource_path:
		open_save_project_dialog()
		return true
	else:
		Globals.current_file.pre_save()
		ResourceSaver.save(Globals.current_file.resource_path,
				Globals.current_file)
		return false


func start_empty_project() -> void:
	var new_file := SaveFile.new()
	Globals.set_current_file(new_file)
	Globals.mesh = preload("res://misc/cube.obj")


func open_save_project_dialog() -> void:
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.res,*.tres;Material Painter File"]
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.current_file = ""
	file_dialog.set_meta("to_save", Globals.current_file)
	file_dialog.popup_centered()


func do_change_mask_action(action_name : String, layer, mask : LayerTexture) -> void:
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(self, "set_mask", layer, mask)
	undo_redo.add_undo_method(self, "set_mask", layer, layer.mask)
	undo_redo.commit_action()


func initialise_layouts() -> void:
	var dir := Directory.new()
	dir.make_dir_recursive("user://layouts")
	var default := LAYOUTS_FOLDER.plus_file("default.json")
	if not dir.file_exists(default):
		# wait for all windows to be ready
		yield(get_tree(), "idle_frame")
		LayoutUtils.save_layout(root.get_child(0), default)
	else:
		yield(get_tree(), "idle_frame")
		LayoutUtils.load_layout(root, default)
	view_menu_button.update_layout_options()
