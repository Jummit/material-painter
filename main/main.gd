extends Control

"""
The main script of the Material Painter application

It handles most callbacks and updates the results of the layer stacks when something changes.
Keeps track of the currently editing objects and manages the menu bar, saving and loading.
"""

var current_file : SaveFile

var editing_layer_material : LayerMaterial
var editing_layer_texture : LayerTexture
var editing_texture_layer : TextureLayer
var editing_material_layer : MaterialLayer

var result_size := Vector2(64, 64)

const SaveFile = preload("res://main/save_file.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerMaterial = preload("res://material_layers/layer_material.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var material_layer_tree : Tree = $VBoxContainer/PanelContainer/LayerContainer/MaterialLayerPanel/MaterialLayerTree
onready var material_layer_property_panel : Panel = $VBoxContainer/PanelContainer/LayerContainer/MaterialLayerPanel/MaterialLayerPropertyPanel
onready var texture_layer_property_panel : Panel = $VBoxContainer/PanelContainer/LayerContainer/TextureLayerPanel/TextureLayerPropertyPanel
onready var texture_layer_tree : Tree = $VBoxContainer/PanelContainer/LayerContainer/TextureLayerPanel/TextureLayerTree
onready var texture_blending_viewport : Viewport = $TextureBlendingViewport
onready var masked_texture_blending_viewport : Viewport = $MaskedTextureBlendingViewport
onready var normal_map_generation_viewport : Viewport = $NormalMapGenerationViewport
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/LayerContainer/VBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"

func _ready():
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")
	load_file(SaveFile.new())


func generate_layer_material_textures(layer_material : LayerMaterial) -> void:
	# todo: clear all maps before applying, as some may have been removed
	for type in Globals.TEXTURE_MAP_TYPES:
		generate_layer_material_channel_texture(layer_material, type)


func generate_layer_material_channel_texture(layer_material : LayerMaterial, type : String) -> void:
	var layers := []
	var options := []
	
	for layer in layer_material.layers:
		# todo: add height instead of masking it
		layer = layer as MaterialLayer
		if layer.properties.has(type) and layer.properties[type]:
			if not layer.properties[type].result:
				yield(generate_layer_texture_result(layer.properties[type]), "completed")
			if layer.properties.mask and not layer.properties.mask.result:
				yield(generate_layer_texture_result(layer.properties.mask), "completed")
			
			layers.append(layer.properties[type].result)
			options.append({
				mask = null if not layer.properties.mask else layer.properties.mask.result
			})
	
	if not layers.empty():
		var result : ImageTexture = yield(masked_texture_blending_viewport.blend(layers, options, result_size), "completed")
		layer_material.results[type] = result
		if type == "height":
			var normal_texture : ImageTexture = yield(normal_map_generation_viewport.get_normal_map(result), "completed")
			model.get_surface_material(0).normal_texture = normal_texture
			layer_material.results.normal = normal_texture
		else:
			model.get_surface_material(0).set(type + "_texture", result)


func generate_layer_texture_result(layer_texture : LayerTexture) -> void:
	var layers := []
	var options := []
	
	for layer in layer_texture.layers:
		layer = layer as TextureLayer
		if layer.texture:
			layers.append(layer.texture)
			options.append(layer.properties)
	
	layer_texture.result = yield(texture_blending_viewport.blend(layers, options, result_size), "completed")


func load_file(save_file : SaveFile) -> void:
	current_file = save_file
	editing_layer_material = current_file.layer_material
	material_layer_tree.items = editing_layer_material.layers
	material_layer_tree.update_tree()
	
	TextureManager.load_textures_from_layer_material(current_file.layer_material)
	generate_layer_material_textures(editing_layer_material)


func export_textures(to_folder : String, layer_material : LayerMaterial) -> void:
	var results := layer_material.results
	for type in results.keys():
		results[type].get_data().save_png(to_folder.plus_file(type) + ".png")


func add_texture_layer(texture_layer : TextureLayer) -> void:
	texture_layer.generate_texture()
	editing_layer_texture.layers.append(texture_layer)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()
	generate_layer_texture_result(editing_layer_texture)
	generate_layer_material_textures(editing_layer_material)


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
			if current_file.resource_path:
				export_textures(current_file.resource_path.get_base_dir(),
						current_file.layer_material)


func _on_FileDialog_file_selected(path : String):
	match file_dialog.mode:
		FileDialog.MODE_SAVE_FILE:
			ResourceSaver.save(path, current_file)
		FileDialog.MODE_OPEN_FILE:
			load_file(load(path))


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])
		node.connect("changed", self, "_on_TextureOption_changed")


func _on_TextureOption_changed():
	generate_layer_material_textures(editing_layer_material)


func _on_TextureOption_selected(texture_option : TextureOption):
	editing_layer_texture = texture_option.selected_texture
	texture_layer_tree.load_layer_texture(editing_layer_texture)


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer) -> void:
	add_texture_layer(texture_layer)


func _on_TextureLayerTree_layer_selected(texture_layer : TextureLayer) -> void:
	editing_texture_layer = texture_layer
	texture_layer_property_panel.load_texture_layer(editing_texture_layer)


func _on_TextureLayerTree_nothing_selected() -> void:
	if not texture_layer_tree.get_selected():
		editing_texture_layer = null


func _on_TextureLayerPropertyPanel_values_changed() -> void:
	editing_texture_layer.properties = texture_layer_property_panel.get_property_values()
	editing_texture_layer.generate_texture()
	texture_layer_tree.update_icons()
	generate_layer_texture_result(editing_layer_texture)
	generate_layer_material_textures(editing_layer_material)


func _on_AddMaterialLayerButton_pressed() -> void:
	editing_layer_material.layers.append(MaterialLayer.new())
	material_layer_tree.update_tree()


func _on_MaterialLayerTree_layer_selected(material_layer : MaterialLayer) -> void:
	editing_material_layer = material_layer
	material_layer_property_panel.load_material_layer(material_layer)


func _on_MaterialLayerTree_nothing_selected() -> void:
	if not material_layer_tree.get_selected():
		editing_material_layer = null


func _on_MaterialLayerPropertyPanel_values_changed() -> void:
	editing_material_layer.properties = material_layer_property_panel.get_property_values()
	generate_layer_material_textures(editing_layer_material)


func _on_TextureChannelButtons_changed() -> void:
	material_layer_property_panel.load_material_layer(editing_material_layer)


func _on_3DViewport_painted() -> void:
	generate_layer_texture_result(editing_layer_texture)
	generate_layer_material_textures(editing_layer_material)
	texture_layer_tree.update_icons()


func _on_2DViewport_painted() -> void:
	generate_layer_texture_result(editing_layer_texture)
	generate_layer_material_textures(editing_layer_material)
	texture_layer_tree.update_icons()
