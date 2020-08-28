extends "res://addons/arrangable_tree/arrangable_tree.gd"

const MaterialLayer = preload("res://material_layers/material_layer.gd")

func setup_item(layer_item : TreeItem, layer : MaterialLayer) -> void:
	layer_item.set_text(0, layer.name)
	layer_item.set_editable(0, true)


func _on_AddMaterialLayerButton_pressed():
	var new_layer := MaterialLayer.new()
	layers.append(new_layer)
	update_tree()


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(0)
