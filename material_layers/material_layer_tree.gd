extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var material_layer_property_panel : Panel = $"../MaterialLayerPropertyPanel"
onready var texture_layer_tree : Tree = $"../../TextureLayerContainer/TextureLayerTree"
onready var texture_blending_viewport : Viewport = $"../../../TextureBlendingViewport"
onready var model : MeshInstance = $"../../3DViewport/Viewport/Model"

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

func setup_item(tree_item : TreeItem, item : MaterialLayer) -> void:
	tree_item.set_text(0, item.name)
	# todo: make renaming better
#	tree_item.set_editable(0, true)


func update_result() -> void:
	print("Generating final material")
	# todo: what does this code do?
	var material_layer : MaterialLayer = get_selected().get_metadata(0)
	var properties : Dictionary = material_layer_property_panel.get_property_values()
	material_layer.properties = properties
	
	for type in Globals.TEXTURE_MAP_TYPES:
		update_channel(type)


func update_channel(type : String) -> void:
	print("Generating channel %s" % type)
	var map_layers = []
	for layer in items:
		layer = layer as MaterialLayer
		if layer.properties.has(type) and layer.properties[type] and layer.properties[type].result:
			map_layers.append(layer.properties[type].result)
	# todo: use mask and correct blend modes
	var result : ImageTexture = yield(texture_blending_viewport.blend(map_layers), "completed")
	model.get_surface_material(0).set(type + "_texture", result)


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(0)


func _on_AddMaterialLayerButton_pressed():
	items.append(MaterialLayer.new())
	update_tree()


func _on_MaterialLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = material_layer_property_panel.get_property_values()
	update_result()


func _on_TextureLayerPropertyPanel_values_changed():
	var editing_layer_texture : LayerTexture = texture_layer_tree.editing_layer_texture
	for layer in items:
		layer = layer as MaterialLayer
		for channel in layer.properties.keys():
			if layer.properties[channel] == editing_layer_texture:
				update_channel(channel)
				return


func _input(event):
	if event.is_action_pressed("save"):
		for type in Globals.TEXTURE_MAP_TYPES:
			var t = model.get_surface_material(0).get(type + "_texture")
			if t:
				t.get_data().save_png("res://export/%s.png" % type)
