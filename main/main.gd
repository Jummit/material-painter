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
var selected_tool : int = Tools.PAINT

enum Tools {
	PAINT,
	TRIANGLE,
	UV_ISLANDS,
}

const MATERIAL_PATH := "user://materials"

const ObjParser = preload("res://addons/gd-obj/obj_parser.gd")
const SaveFile = preload("res://main/save_file.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const LayerMaterial = preload("res://layers/layer_material.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const FolderLayer = preload("res://layers/folder_layer.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_property_panel : Panel = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerPropertyPanel
onready var texture_channel_buttons : GridContainer = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/TextureChannelButtons
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"
onready var layer_tree : Tree = $VBoxContainer/PanelContainer/HBoxContainer/LayerPanelContainer/LayerTree
onready var results_item_list : ItemList = $VBoxContainer/PanelContainer/HBoxContainer/ResultsItemList
onready var painter : Node = $"VBoxContainer/PanelContainer/HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewport/Painter"

func _ready():
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	load_file(SaveFile.new())


func load_file(save_file : SaveFile) -> void:
	current_file = save_file
	if current_file.model_path:
		load_model(current_file.model_path)
	editing_layer_material = current_file.layer_material
	layer_tree.setup_layer_material(editing_layer_material)


func add_texture_layer(texture_layer, onto : Array) -> void:
	onto.append(texture_layer)
	editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.setup_layer_material(editing_layer_material)


func add_material_layer(material_layer, onto : Array) -> void:
	onto.append(material_layer)
	editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.setup_layer_material(editing_layer_material)


func load_model(path : String) -> void:
	model.set_mesh(ObjParser.parse_obj(path))


func _on_FileDialog_file_selected(path : String):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			var to_save = file_dialog.get_meta("to_save")
			if to_save is SaveFile:
				file_location = path
			ResourceSaver.save(path, to_save)
		FileDialog.MODE_OPEN_FILE:
			if path.get_extension() == "tres":
				file_location = path
				load_file(load(path))
			elif path.get_extension() == "obj":
				current_file.model_path = path
				load_model(path)


func _on_AddButton_pressed() -> void:
	if layer_tree.get_selected() and layer_tree.get_selected_material_layer() is FolderLayer:
		add_material_layer(MaterialLayer.new(), layer_tree.get_selected_material_layer().layers)
	else:
		add_material_layer(MaterialLayer.new(), editing_layer_material.layers)


func _on_AddFolderButton_pressed() -> void:
	if layer_tree.get_selected() and layer_tree.get_selected_material_layer() is FolderLayer:
		add_material_layer(FolderLayer.new(), layer_tree.get_selected_material_layer().layers)
	elif layer_tree.get_selected() and layer_tree.get_selected_material_layer() is MaterialLayer and layer_tree.get_selected_material_layer() in layer_tree.selected_layer_textures:
		add_material_layer(FolderLayer.new(), layer_tree.selected_layer_textures[layer_tree.get_selected_material_layer()].layers)
	else:
		add_material_layer(FolderLayer.new(), editing_layer_material.layers)


func _on_DeleteButton_pressed() -> void:
	if not layer_tree.get_selected():
		return
	var layer = layer_tree.get_selected().get_meta("layer")
	layer_tree.get_array_layer_is_in(layer).erase(layer)
	layer_tree.setup_layer_material(editing_layer_material)


func _on_TextureChannelButtons_changed(map : String, activated : bool) -> void:
	if activated:
		layer_tree.selected_maps[layer_property_panel.editing_layer] = layer_property_panel.editing_layer.maps[map]
		layer_tree.selected_layer_textures[layer_property_panel.editing_layer] = layer_property_panel.editing_layer.maps[map]
	layer_tree.setup_layer_material(editing_layer_material)


func _on_LayerTree_material_layer_selected(material_layer) -> void:
	layer_property_panel.load_material_layer(material_layer)
	texture_channel_buttons.load_material_layer(material_layer)


func _on_LayerPropertyPanel_values_changed() -> void:
	layer_property_panel.store_values(layer_property_panel.editing_layer)
	var affected_layers := editing_layer_material.get_depending_layer_textures(layer_property_panel.editing_layer)
	for affected_layer in affected_layers:
		affected_layer.update_result(result_size)
	editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.update_icons()


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	layer_property_panel.load_texture_layer(texture_layer)
	texture_channel_buttons.hide()


func _on_AddLayerPopupMenu_layer_selected(layer) -> void:
	if layer_tree.material_layer_popup_menu.layer is FolderLayer:
		add_texture_layer(layer.new(), layer_tree.material_layer_popup_menu.layer.layers)
	else:
		add_texture_layer(layer.new(), layer_tree.selected_layer_textures[layer_tree.material_layer_popup_menu.layer].layers)


func _on_FileMenu_id_pressed(id : int):
	match id:
		0:
			load_file(SaveFile.new())
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


func _on_MaterialLayerPopupMenu_layer_saved() -> void:
	var material_layer = layer_tree.get_selected_material_layer()
	ResourceSaver.save(MATERIAL_PATH.plus_file(material_layer.name) + ".tres", material_layer)


func _on_MaterialLayerPopupMenu_mask_added() -> void:
	var material_layer : MaterialLayer = layer_tree.get_selected_material_layer()
	material_layer.mask = LayerTexture.new()
	layer_tree.setup_layer_material(editing_layer_material)


func _on_LayerTree_layer_visibility_changed(layer) -> void:
	if layer is MaterialLayer:
		editing_layer_material.update_results(result_size)
	elif layer is TextureLayer:
		for affected_layer in editing_layer_material.get_depending_layer_textures(layer):
			affected_layer.update_result(result_size)
		editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.update_icons()


func _on_Viewport_painted(layer : TextureLayer) -> void:
	for affected_layer in editing_layer_material.get_depending_layer_textures(layer):
		affected_layer.update_result(result_size)
	editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.update_icons()


func _on_MaterialLayerPopupMenu_mask_removed() -> void:
	layer_tree.get_selected_material_layer().mask = null
	editing_layer_material.update_results(result_size)
	results_item_list.load_layer_material(editing_layer_material)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.setup_layer_material(editing_layer_material)


func _on_ToolButtonContainer_tool_selected(tool_id : int):
	selected_tool = tool_id


func _on_SaveButton_pressed() -> void:
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.current_dir = "user://brushes/"
	file_dialog.current_path = "user://brushes/"
	file_dialog.current_file = ""
	file_dialog.mode = FileDialog.MODE_SAVE_FILE
	file_dialog.filters = ["*.tres;Brush File"]
	file_dialog.set_meta("to_save", painter.brush)
	file_dialog.popup_centered()

