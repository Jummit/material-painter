extends Control

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var material_layer_panel : VBoxContainer = $VBoxContainer/PanelContainer/LayerContainer/MaterialLayerPanel
onready var texture_layer_panel : VBoxContainer = $VBoxContainer/PanelContainer/LayerContainer/TextureLayerPanel
onready var file_dialog : FileDialog = $FileDialog
onready var texture_blending_viewport : Viewport = $TextureBlendingViewport
onready var masked_texture_blending_viewport : Viewport = $MaskedTextureBlendingViewport
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/LayerContainer/VBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"

const SaveFile = preload("res://main/save_file.gd")

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
		if layer.properties.has(type) and layer.properties[type]:
			if not layer.properties[type].result:
				yield(update_layer_texture(layer.properties[type]), "completed")
			if layer.properties.mask and not layer.properties.mask.result:
				yield(update_layer_texture(layer.properties.mask), "completed")
			
			textures.append(layer.properties[type].result)
			options.append({
				mask = null if not layer.properties.mask else layer.properties.mask.result
			})
	
	if not textures.empty():
		var result : ImageTexture = yield(masked_texture_blending_viewport.blend(textures, options), "completed")
		layer_material.results[type] = result
		model.get_surface_material(0).set(type + "_texture", result)


func update_layer_texture(layer_texture : LayerTexture) -> void:
	var textures := []
	var options := []
	
	for layer in layer_texture.layers:
		layer = layer as TextureLayer
		textures.append(layer.texture)
		options.append({
			blend_mode = layer.properties.blend_mode,
			opacity = layer.properties.opacity,
		})
	
	var result : Texture = yield(texture_blending_viewport.blend(textures, options), "completed")
	layer_texture.result = result
	# todo: only update correct channel
	update_layer_material(material_layer_panel.editing_layer_material)


func load_material(path : String) -> void:
	current_file = load(path)
	TextureManager.load_textures_from_layer_material(current_file.layer_material)
	for layer_texture in TextureManager.textures:
		update_layer_texture(layer_texture)
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
		3:
			if not current_file.resource_path:
				return
			var export_folder := current_file.resource_path.get_base_dir()
			var results : Dictionary = current_file.layer_material.results
			for type in results.keys():
				(results[type] as ImageTexture).get_data().save_png(export_folder.plus_file(type) + ".png")


func _on_FileDialog_file_selected(path : String):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			save_material(path)
		FileDialog.MODE_OPEN_FILE:
			load_material(path)


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])
		node.connect("changed", self, "_on_TextureOption_changed")


func _on_TextureOption_changed():
	update_layer_material(material_layer_panel.editing_layer_material)


func _on_TextureOption_selected(texture_option : TextureOption):
	texture_layer_panel.load_layer_texture(texture_option.selected_texture)
