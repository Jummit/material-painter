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

const MATERIAL_PATH := "user://materials"

const ObjParser = preload("res://addons/gd-obj/obj_parser.gd")
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
onready var layer_property_panel : Panel = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerPropertyPanel
onready var texture_map_buttons : GridContainer = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/TextureMapButtons
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"
onready var layer_tree : Tree = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerTree
onready var results_item_list : ItemList = $VBoxContainer/PanelContainer/HBoxContainer/ResultsItemList
onready var painter : Node = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Painter"
onready var asset_browser : TabContainer = $VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/AssetBrowser

func _ready() -> void:
	var popup := file_menu_button.get_popup()
	popup.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	popup.set_item_shortcut(0, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_N))
	popup.set_item_shortcut(1, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_O))
	popup.set_item_shortcut(2, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_S))
	popup.set_item_shortcut(3, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_E))
	popup.set_item_shortcut(4, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_M))
	popup.set_item_shortcut(5, ShortcutUtils.shortcut(KEY_MASK_CTRL + KEY_Q))
	_load_file(SaveFile.new())
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
				asset_browser.register_asset(path.get_file(), asset_browser.ASSET_TYPES.BRUSH)
		FileDialog.MODE_OPEN_FILE:
			if path.get_extension() == "tres":
				file_location = path
				_load_file(load(path))
			elif path.get_extension() == "obj":
				current_file.model_path = path
				_load_model(path)


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
	undo_redo.add_do_method(layer_property_panel, "set_property_value", property, value)
	undo_redo.add_do_method(affected_layer, "update_result", result_size)
	undo_redo.add_do_method(self, "_update_results")
	undo_redo.add_undo_property(layer_property_panel.editing_layer, property, layer_property_panel.editing_layer.get(property))
	undo_redo.add_undo_method(affected_layer, "update_result", result_size)
	undo_redo.add_undo_method(layer_property_panel, "set_property_value", property, layer_property_panel.editing_layer.get(property))
	undo_redo.add_undo_method(self, "_update_results")
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
	ResourceSaver.save(MATERIAL_PATH.plus_file(material_layer.name) + ".tres", material_layer)
	asset_browser.register_asset(material_layer.name + ".tres", asset_browser.ASSET_TYPES.MATERIAL)


func _on_Viewport_painted(layer : TextureLayer) -> void:
	editing_layer_material.get_parent(layer).update_result(result_size)
	_update_results()


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


func _on_FileMenu_id_pressed(id : int) -> void:
	match id:
		0:
			_load_file(SaveFile.new())
		1:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.filters = ["*.tres;Material Painter File"]
			file_dialog.popup_centered()
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		2:
			file_dialog.mode = FileDialog.MODE_SAVE_FILE
			file_dialog.filters = ["*.tres;Material Painter File"]
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.set_meta("to_save", current_file)
			file_dialog.popup_centered()
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		3:
			if file_location:
				editing_layer_material.export_textures(file_location.get_base_dir())
		4:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.filters = ["*.obj;Object File"]
			file_dialog.popup_centered()
			file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
			file_dialog.current_file = ""
			file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		5:
			get_tree().quit()


func _on_UndoRedo_version_changed() -> void:
	if undo_redo.get_current_action_name():
		print(undo_redo.get_current_action_name())


func _load_file(save_file : SaveFile) -> void:
	current_file = save_file
	if current_file.model_path:
		_load_model(current_file.model_path)
	editing_layer_material = current_file.layer_material
	editing_layer_material.update_all_layer_textures(result_size)
	_update_results(false)
	layer_tree.editing_layer_material = editing_layer_material


func _load_model(path : String) -> void:
	model.set_mesh(ObjParser.parse_obj(path))


func _update_results(update_icons := true) -> void:
	var result = editing_layer_material.update_results(result_size)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	if update_icons:
		layer_tree.update_icons()


func _update_all_layer_textures(layers : Array) -> void:
	for layer in layers:
		if layer is MaterialLayer:
			yield(layer.update_all_layer_textures(result_size), "completed")
		else:
			yield(_update_all_layer_textures(layer.layers), "completed")
