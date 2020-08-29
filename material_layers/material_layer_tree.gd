extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var material_layer_property_panel : Panel = $"../MaterialLayerPropertyPanel"

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

func setup_item(layer_item : TreeItem, layer : MaterialLayer) -> void:
	layer_item.set_text(0, layer.name)
	layer_item.set_editable(0, true)


func _on_AddMaterialLayerButton_pressed():
	var new_layer := MaterialLayer.new()
	layers.append(new_layer)
	update_tree()


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(0)


func _on_MaterialLayerPropertyPanel_values_changed():
	var material_layer : MaterialLayer = get_selected().get_metadata(0)
	var properties : Dictionary = material_layer_property_panel.get_property_values()
	material_layer.properties = properties
