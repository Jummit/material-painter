extends Control

"""
The main script of the Material Painter application

It handles most callbacks and updates the results of the layer stacks when something changes.
Keeps track of the currently editing objects and manages the menu bar, saving and loading.
"""

var current_file : SaveFile
var file_location : String
var editing_layer_material : LayerMaterial
var result_size := Vector2(2048, 2048)

const SaveFile = preload("res://main/save_file.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const LayerMaterial = preload("res://layers/layer_material.gd")
const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_property_panel : Panel = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/LayerPropertyPanel
onready var texture_channel_buttons : GridContainer = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/TextureChannelButtons
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/LayerContainer/VBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"
onready var layer_tree : Tree = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/LayerTree

func _ready():
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	load_file(SaveFile.new())


func load_file(save_file : SaveFile) -> void:
	current_file = save_file
	editing_layer_material = current_file.layer_material
	TextureManager.load_textures_from_layer_material(current_file.layer_material)
	layer_tree.setup_layer_material(editing_layer_material)


func add_texture_layer(texture_layer : TextureLayer, on_layer_texture : LayerTexture) -> void:
	on_layer_texture.layers.append(texture_layer)
	layer_tree.setup_layer_material(editing_layer_material)


func add_material_layer(material_layer : MaterialLayer) -> void:
	editing_layer_material.layers.append(material_layer)
	layer_tree.setup_layer_material(editing_layer_material)


func _on_FileDialog_file_selected(path : String):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			file_location = path
			ResourceSaver.save(path, current_file)
		FileDialog.MODE_OPEN_FILE:
			file_location = path
			load_file(load(path))


func _on_AddButton_pressed() -> void:
	add_material_layer(MaterialLayer.new())


func _on_DeleteButton_pressed() -> void:
	pass # Replace with function body.


func _on_TextureChannelButtons_changed() -> void:
	layer_tree.setup_layer_material(editing_layer_material)


func _on_LayerTree_material_layer_selected(material_layer) -> void:
	layer_property_panel.load_material_layer(material_layer)
	texture_channel_buttons.load_material_layer(material_layer)


func _on_LayerPropertyPanel_values_changed() -> void:
	layer_property_panel.editing_layer.properties = layer_property_panel.get_property_values()
	var affected_layers := editing_layer_material.get_depending_layer_textures(layer_property_panel.editing_layer)
	affected_layers.front().generate_result(result_size)
	editing_layer_material.generate_results(result_size)
	model.load_layer_material_maps(editing_layer_material)
	layer_tree.update_icons()


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	layer_property_panel.load_texture_layer(texture_layer)
	texture_channel_buttons.hide()


func _on_AddLayerPopupMenu_layer_selected(layer) -> void:
	add_texture_layer(layer.new(), layer_tree.get_selected_layer_texture())


func _on_FileMenu_id_pressed(id : int):
	match id:
		0:
			load_file(SaveFile.new())
		1:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.popup_centered()
		2:
			file_dialog.mode = FileDialog.MODE_SAVE_FILE
			file_dialog.popup_centered()
		3:
			if file_location:
				editing_layer_material.export_textures(file_location.get_base_dir())


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])
#		node.connect("changed", self, "_on_TextureOption_changed")
