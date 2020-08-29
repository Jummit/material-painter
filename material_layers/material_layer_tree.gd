extends "res://addons/arrangable_tree/arrangable_tree.gd"

const MaterialLayer = preload("res://material_layers/material_layer.gd")

func setup_item(tree_item : TreeItem, item : MaterialLayer) -> void:
	tree_item.set_text(0, item.name)
#	tree_item.set_editable(0, true)


func _on_item_edited():
	# todo: make renaming better
	get_selected().get_metadata(0).name = get_selected().get_text(0)
