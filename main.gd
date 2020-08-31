extends Control

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/FileMenuButton
onready var material_layer_panel : VBoxContainer = $VBoxContainer/PanelContainer/LayerContainer/MaterialLayerPanel
onready var texture_layer_panel : VBoxContainer = $VBoxContainer/PanelContainer/LayerContainer/TextureLayerPanel
onready var file_dialog : FileDialog = $FileDialog
onready var masked_texture_blending_viewport : Viewport = $MaskedTextureBlendingViewport
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/LayerContainer/VBoxContainer/3DViewport/Viewport/Model"

const SaveFile = preload("res://save_file.gd")

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerMaterial = preload("res://material_layers/layer_material.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")

var current_file := SaveFile.new()

func _ready():
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	material_layer_panel.editing_layer_material = current_file.layer_material
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func update_layer_material(layer_material : LayerMaterial) -> void:
	for type in Globals.TEXTURE_MAP_TYPES:
		update_layer_material_channel(layer_material, type)


func update_layer_material_channel(layer_material : LayerMaterial, type : String) -> void:
	var textures := []
	var options := []
	for layer in layer_material.layers:
		layer = layer as MaterialLayer
		if layer.properties.has(type) and layer.properties[type] and layer.properties[type].result and layer.properties.mask:
			textures.append(layer.properties[type].result)
			options.append({
				mask = layer.properties.mask.result
			})
	
	if not textures.empty():
		var result : ImageTexture = yield(masked_texture_blending_viewport.blend(textures, options), "completed")
		model.get_surface_material(0).set(type + "_texture", result)


func load_material(path : String) -> void:
	current_file = load(path)
	TextureManager.load_textures_from_layer_material(current_file.layer_material)
	material_layer_panel.editing_layer_material = current_file.layer_material


func save_material(path : String) -> void:
	ResourceSaver.save(path, current_file)


func _on_FileMenu_id_pressed(id : int):
	match id:
		0:
			current_file = SaveFile.new()
			material_layer_panel.editing_layer_material = current_file.layer_material
		1:
			file_dialog.mode = FileDialog.MODE_OPEN_FILE
			file_dialog.popup_centered()
		2:
			file_dialog.mode = FileDialog.MODE_SAVE_FILE
			file_dialog.popup_centered()


func _on_FileDialog_file_selected(path : String):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			save_material(path)
		FileDialog.MODE_OPEN_FILE:
			load_material(path)


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])


func _on_TextureOption_selected(texture_option : TextureOption):
	texture_layer_panel.load_layer_texture(texture_option.selected_texture)
	update_layer_material(material_layer_panel.editing_layer_material)
