extends Control

"""
The main script of the Material Painter application

It handles most callbacks and updates the results of the layer stacks when something changes.
Keeps track of the currently editing objects and manages the menu bar, saving and loading.
"""

var current_file : SaveFile
var editing_layer_material : LayerMaterial
var result_size := Vector2(2048, 2048)
var editing_layer

const SaveFile = preload("res://main/save_file.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerMaterial = preload("res://material_layers/layer_material.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const TextureOption = preload("res://texture_option/texture_option.gd")
const BitmapTextureLayer = preload("res://texture_layers/types/bitmap_texture_layer.gd")
const Layer = preload("res://render_viewports/layer_blending_viewport/layer_blending_viewport.gd").Layer

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/TopButtons/FileMenuButton
onready var file_dialog : FileDialog = $FileDialog
onready var layer_blending_viewport : Viewport = $LayerBlendingViewport
onready var normal_map_generation_viewport : Viewport = $NormalMapGenerationViewport
onready var layer_property_panel : Panel = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/LayerPropertyPanel
onready var texture_channel_buttons : GridContainer = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/TextureChannelButtons
onready var model : MeshInstance = $"VBoxContainer/PanelContainer/LayerContainer/VBoxContainer/ViewportTabContainer/3DViewport/Viewport/Model"
onready var layer_tree : Tree = $VBoxContainer/PanelContainer/LayerContainer/LayerTree/LayerTree

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
	
	for layer in layer_material.layers:
		if not (type in layer.properties and layer.properties[type]):
			continue
		var shader_layer := Layer.new()
		shader_layer.code = "texture({0}, UV).rgb"
		if "mask" in layer.properties and layer.properties.mask:
			shader_layer.mask = layer.properties.mask.result
		shader_layer.uniform_types = ["sampler2D"]
		shader_layer.uniform_values = [layer.properties[type].result]
		layers.append(shader_layer)
	
	if layers.empty():
		return
	
	var result : Texture = yield(layer_blending_viewport.blend(layers, result_size), "completed")
	if type == "height":
		var normal_texture : ImageTexture = yield(normal_map_generation_viewport.get_normal_map(result), "completed")
		model.get_surface_material(0).normal_texture = normal_texture
		layer_material.results.normal = normal_texture
	else:
		model.get_surface_material(0).set(type + "_texture", result)
		layer_material.results[type] = result


func generate_texture_layer_result(texture_layer : TextureLayer) -> void:
	texture_layer.result = yield(layer_blending_viewport.blend(
			[texture_layer._get_as_shader_layer()], result_size), "completed")


func generate_layer_texture_result(layer_texture : LayerTexture) -> void:
	var layers := []
	for layer in layer_texture.layers:
		layers.append(layer._get_as_shader_layer())
	layer_texture.result = yield(layer_blending_viewport.blend(layers, result_size), "completed")


func load_file(save_file : SaveFile) -> void:
	current_file = save_file
	editing_layer_material = current_file.layer_material
	
	TextureManager.load_textures_from_layer_material(current_file.layer_material)
	generate_layer_material_textures(editing_layer_material)
	
	layer_tree.setup_layer_material(editing_layer_material)


func export_textures(to_folder : String, layer_material : LayerMaterial) -> void:
	var results := layer_material.results
	for type in results.keys():
		results[type].get_data().save_png(to_folder.plus_file(type) + ".png")


func add_texture_layer(texture_layer : TextureLayer, on_layer_texture : LayerTexture) -> void:
	on_layer_texture.layers.append(texture_layer)
	generate_texture_layer_result(texture_layer)
	layer_tree.setup_layer_material(editing_layer_material)
#	layer_tree.add_texture_layer(texture_layer, layer_tree.get_selected_material_layer())


func add_material_layer(material_layer : MaterialLayer) -> void:
	editing_layer_material.layers.append(material_layer)
#	layer_tree.add_material_layer(material_layer)
	layer_tree.setup_layer_material(editing_layer_material)


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


func _on_AddButton_pressed() -> void:
	add_material_layer(MaterialLayer.new())


func _on_DeleteButton_pressed() -> void:
	pass # Replace with function body.


func _on_AddLayerPopupMenu_id_pressed(_id : int) -> void:
	add_texture_layer(BitmapTextureLayer.new(), layer_tree.get_selected_layer_texture())


func _on_TextureChannelButtons_changed() -> void:
	layer_tree.setup_layer_material(editing_layer_material)


func _on_LayerTree_layer_texture_selected(_layer_texture) -> void:
	pass


func _on_LayerTree_material_layer_selected(material_layer) -> void:
	editing_layer = material_layer
	layer_property_panel.load_material_layer(material_layer)
	texture_channel_buttons.load_material_layer(material_layer)


func _on_LayerPropertyPanel_values_changed() -> void:
	editing_layer.properties = layer_property_panel.get_property_values()
	layer_tree.setup_layer_material(editing_layer_material)


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	editing_layer = texture_layer
	layer_property_panel.load_texture_layer(texture_layer)
	texture_channel_buttons.hide()
