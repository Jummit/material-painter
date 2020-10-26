extends Control

"""
The main script of the Material Painter application

It handles most callbacks and updates the results of the layer stacks when something changes.
Manages the menu bar, saving and loading.
"""

var current_file : SaveFile
var file_location : String
var editing_layer_material : LayerMaterial
var result_size := Vector2(2048, 2048)
var undo_redo := UndoRedo.new()
var currently_viewing_map : String setget set_currently_viewing_map

var _mesh_maps_generator = preload("res://main/mesh_maps_generator.gd").new()

const MATERIAL_PATH := "user://materials"

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

const ObjParser = preload("res://addons/obj_parser/obj_parser.gd")
const ShortcutUtils = preload("res://utils/shortcut_utils.gd")
const SaveFile = preload("res://resources/save_file.gd")
const MaterialLayer = preload("res://resources/material_layer.gd")
const LayerMaterial = preload("res://resources/layer_material.gd")
const LayerTexture = preload("res://resources/layer_texture.gd")
const TextureLayer = preload("res://resources/texture_layer.gd")
const FolderLayer = preload("res://resources/folder_layer.gd")
const Brush = preload("res://addons/painter/brush.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var edit_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/EditMenuButton
onready var layer_property_panel : Panel = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerPropertyPanel
onready var texture_map_buttons : GridContainer = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/TextureMapButtons
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"
onready var layer_tree : Tree = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerTree
onready var results_item_list : ItemList = $VBoxContainer/PanelContainer/HBoxContainer/ResultsItemList
onready var painter : Node = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Painter"
onready var asset_browser : HBoxContainer = $VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/AssetBrowser
onready var material_option_button : OptionButton = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/HBoxContainer/MaterialOptionButton
onready var camera : Camera = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Viewport/RotatingCamera/HorizontalCameraSocket/Camera"

func _ready() -> void:
	var popup := file_menu_button.get_popup()
	popup.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	for id in file_menu_shortcuts.size():
		popup.set_item_shortcut(id, file_menu_shortcuts[id])
	
	edit_menu_button.get_popup().connect("id_pressed", self, "_on_EditMenu_id_pressed")
	
	var file := SaveFile.new()
	file.model_path = "res://3d_viewport/cube.obj"
	_load_file(file)
	undo_redo.connect("version_changed", self, "_on_UndoRedo_version_changed")


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
	elif event.is_action_pressed("ui_cancel"):
		set_currently_viewing_map("")


func add_layer(layer, onto) -> void:
	onto.layers.append(layer)
	var onto_layer_texture : LayerTexture = editing_layer_material.get_layer_texture_of_texture_layer(layer)
	if onto_layer_texture:
		yield(editing_layer_material.get_layer_texture_of_texture_layer(layer).update_result(result_size), "completed")
	else:
		if layer is MaterialLayer:
			var result = layer.update_all_layer_textures(result_size)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		else:
			var result = _update_all_layer_textures(layer.layers)
			if result is GDScriptFunctionState:
				yield(result, "completed")
	_update_results()
	layer_tree.reload()


func delete_layer(layer) -> void:
	var layer_texture : LayerTexture
	var array_layer_is_in : Array
	if layer is TextureLayer:
		layer_texture = editing_layer_material.get_layer_texture_of_texture_layer(layer)
		array_layer_is_in = layer_texture.layers
	else:
		array_layer_is_in = editing_layer_material.get_parent(layer).layers
	array_layer_is_in.erase(layer)
	if layer_texture:
		layer_texture.update_result(result_size)
	_update_results(false)
	layer_tree.reload()


func _on_FileDialog_file_selected(path : String) -> void:
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			var to_save = file_dialog.get_meta("to_save")
			if to_save is SaveFile:
				file_location = path
			ResourceSaver.save(path, to_save)
			if to_save is Brush:
				asset_browser.load_asset(path, asset_browser.ASSET_TYPES.BRUSH)
				asset_browser.update_asset_list()
		FileDialog.MODE_OPEN_FILE:
			if path.get_extension() == "tres":
				file_location = path
				_load_file(ResourceLoader.load(path, "", true))
#				_load_file(load(path))
				asset_browser.load_local_assets(file_location)
				if not "local" in asset_browser.tags:
					asset_browser.tags.append("local")
					asset_browser.update_tag_list()
			elif path.get_extension() == "obj":
				current_file.model_path = path
				_load_model(path)
				editing_layer_material = current_file.layer_materials.front()
				layer_tree.editing_layer_material = current_file.layer_materials.front()


func _on_AddButton_pressed() -> void:
	var onto
	if layer_tree.get_selected_layer() is FolderLayer:
		onto = layer_tree.get_selected_layer()
	else:
		onto = editing_layer_material
	undo_redo.create_action("Add Material Layer")
	var new_layer := MaterialLayer.new()
	undo_redo.add_do_method(self, "add_layer", new_layer, onto)
	undo_redo.add_undo_method(self, "delete_layer", new_layer)
	undo_redo.commit_action()


func _on_AddFolderButton_pressed() -> void:
	undo_redo.create_action("Add Folder Layer")
	var new_layer := FolderLayer.new()
	var onto
	var selected_layer = layer_tree.get_selected_layer()
	if selected_layer is FolderLayer:
		onto = selected_layer
	elif selected_layer is MaterialLayer and layer_tree.get_selected_layer_texture(selected_layer):
		onto = layer_tree.get_selected_layer_texture(selected_layer)
	else:
		onto = editing_layer_material
	undo_redo.add_do_method(self, "add_layer", new_layer, onto)
	undo_redo.add_undo_method(self, "delete_layer", new_layer)
	undo_redo.commit_action()


func _on_DeleteButton_pressed() -> void:
	if layer_tree.get_selected():
		undo_redo.create_action("Delete Layer")
		var selected_layer = layer_tree.get_selected().get_meta("layer")
		undo_redo.add_do_method(self, "delete_layer", selected_layer)
		undo_redo.add_do_method(layer_property_panel, "clear")
		undo_redo.add_do_method(texture_map_buttons, "hide")
		undo_redo.add_undo_method(self, "add_layer", selected_layer, editing_layer_material.get_parent(selected_layer))
		undo_redo.add_undo_method(layer_property_panel, "load_material_layer", selected_layer)
		undo_redo.add_undo_method(texture_map_buttons, "show")
		undo_redo.commit_action()


func _on_TextureMapButtons_changed(map : String, enabled : bool) -> void:
	if enabled:
		layer_tree.select_map(layer_property_panel.editing_layer, map, true)
	layer_tree.reload()
	_update_results(false)


func _on_LayerTree_layer_visibility_changed(layer) -> void:
	if layer is TextureLayer:
		editing_layer_material.get_parent(layer).update_result(result_size)
	_update_results()


func _on_LayerPropertyPanel_property_changed(property : String, value) -> void:
	undo_redo.create_action("Set Layer Property")
	undo_redo.add_do_property(layer_property_panel.editing_layer, property, value)
	var affected_layer : LayerTexture = editing_layer_material.get_parent(layer_property_panel.editing_layer)
	if not affected_layer:
		return
	var use_cashed_shader = not property in ["opacity", "blend_mode"]
	undo_redo.add_do_method(layer_property_panel, "set_property_value", property, value)
	undo_redo.add_do_method(affected_layer, "update_result", result_size, true, use_cashed_shader)
	undo_redo.add_do_method(self, "_update_results", true, use_cashed_shader)
	undo_redo.add_undo_property(layer_property_panel.editing_layer, property, layer_property_panel.editing_layer.get(property))
	undo_redo.add_undo_method(affected_layer, "update_result", result_size, true, use_cashed_shader)
	undo_redo.add_undo_method(layer_property_panel, "set_property_value", property, layer_property_panel.editing_layer.get(property))
	undo_redo.add_undo_method(self, "_update_results", true, use_cashed_shader)
	undo_redo.commit_action()


func _on_AddLayerPopupMenu_layer_selected(layer) -> void:
	undo_redo.create_action("Add Texture Layer")
	var new_layer = layer.new()
	if layer_tree.material_layer_popup_menu.layer is FolderLayer:
		undo_redo.add_do_method(self, "add_layer", new_layer, layer_tree.material_layer_popup_menu.layer)
	else:
		undo_redo.add_do_method(self, "add_layer", new_layer, layer_tree.get_selected_layer_texture(layer_tree.material_layer_popup_menu.layer))
	undo_redo.add_undo_method(self, "delete_layer", new_layer)
	undo_redo.commit_action()


func _on_MaterialLayerPopupMenu_layer_saved() -> void:
	var material_layer = layer_tree.get_selected_layer()
	var save_path := MATERIAL_PATH.plus_file(material_layer.name) + ".tres"
	ResourceSaver.save(save_path, material_layer)
	asset_browser.load_asset(save_path, asset_browser.ASSET_TYPES.MATERIAL)
	asset_browser.update_asset_list()


func _on_Viewport_painted(layer : TextureLayer) -> void:
	editing_layer_material.get_parent(layer).update_result(result_size, true, true)
	_update_results(false, true)


func _on_MaterialLayerPopupMenu_mask_removed() -> void:
	layer_tree.get_selected_layer().mask = null
	_update_results()


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
	editing_layer_material = current_file.layer_materials[index]
	layer_tree.editing_layer_material = editing_layer_material


func _on_ResultsItemList_item_activated(index : int) -> void:
	set_currently_viewing_map(editing_layer_material.results.keys()[index])


# hacky way of preventing zoom when the file dialog is in the way
func _on_FileDialog_about_to_show() -> void:
	camera.set_process_input(false)


func _on_FileDialog_popup_hide() -> void:
	camera.set_process_input(true)


func _on_FileMenu_id_pressed(id : int) -> void:
	match id:
		FILE_MENU_ITEMS.NEW:
			var file := SaveFile.new()
			file.model_path = "res://3d_viewport/cube.obj"
			_load_file(file)
		FILE_MENU_ITEMS.OPEN:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.filters = ["*.tres;Material Painter File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.popup_centered()
		FILE_MENU_ITEMS.SAVE:
			if not file_location:
				_open_save_project_dialog()
			else:
				ResourceSaver.save(file_location, current_file)
		FILE_MENU_ITEMS.SAVE_AS:
			_open_save_project_dialog()
		FILE_MENU_ITEMS.EXPORT:
			if file_location:
				editing_layer_material.export_textures(file_location.get_base_dir())
		FILE_MENU_ITEMS.LOAD_MESH:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
			file_dialog.filters = ["*.obj;Object File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.popup_centered()
		FILE_MENU_ITEMS.QUIT:
			get_tree().quit()


func _on_EditMenu_id_pressed(_id : int) -> void:
	var mesh_maps : Dictionary = yield(_mesh_maps_generator.generate_mesh_maps(Globals.mesh, Vector2(1024, 1024)), "completed")
	var texture_dir : String = asset_browser.ASSET_TYPES.TEXTURE.get_local_asset_directory(file_location)
	for map in mesh_maps:
		var file := texture_dir.plus_file(map) + ".png"
		mesh_maps[map].get_data().save_png(file)
		asset_browser.load_asset(file, asset_browser.ASSET_TYPES.TEXTURE, "local")
	asset_browser.update_asset_list()


func _on_UndoRedo_version_changed() -> void:
	if undo_redo.get_current_action_name():
		print(undo_redo.get_current_action_name())


func _load_file(save_file : SaveFile) -> void:
	current_file = save_file
	if current_file.model_path:
		_load_model(current_file.model_path)
		for layer_material in current_file.layer_materials:
			var result = layer_material.update_all_layer_textures(result_size)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		editing_layer_material = current_file.layer_materials.front()
		_update_results(false)
		layer_tree.editing_layer_material = editing_layer_material
		update_material_options()


func _load_model(path : String) -> void:
	var mesh := ObjParser.parse_obj(path)
	Globals.mesh = mesh
	model.set_mesh(mesh)
	material_option_button.clear()
	current_file.layer_materials.resize(mesh.get_surface_count())
	for surface in mesh.get_surface_count():
		if not current_file.layer_materials[surface]:
			current_file.layer_materials[surface] = LayerMaterial.new()


func update_material_options() -> void:
	material_option_button.clear()
	for material_num in current_file.layer_materials.size():
		material_option_button.add_item("Material %s" % material_num)


func _update_results(update_icons := true, use_cached_shader := false) -> void:
	var result = editing_layer_material.update_results(result_size, use_cached_shader)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	results_item_list.load_layer_material(editing_layer_material)
	if not currently_viewing_map:
		model.load_layer_materials(current_file.layer_materials)
	if update_icons:
		layer_tree.update_icons()


func _update_all_layer_textures(layers : Array) -> void:
	for layer in layers:
		if layer is MaterialLayer:
			yield(layer.update_all_layer_textures(result_size), "completed")
		else:
			yield(_update_all_layer_textures(layer.layers), "completed")


func _open_save_project_dialog() -> void:
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.tres;Material Painter File"]
	file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	file_dialog.current_file = ""
	file_dialog.set_meta("to_save", current_file)
	file_dialog.popup_centered()


func set_currently_viewing_map(to : String) -> void:
	currently_viewing_map = to
	if currently_viewing_map:
		var textures := []
		for layer_material in current_file.layer_materials:
			if currently_viewing_map in layer_material.results:
				textures.append(layer_material.results[currently_viewing_map])
			else:
				textures.append(null)
		model.load_albedo_textures(textures)
	else:
		model.load_layer_materials(current_file.layer_materials)
