extends "res://addons/arrangable_tree/arrangable_tree.gd"

"""
The `ArrangableTree` that represents the layers of the selected MaterialLayer
"""

signal layer_selected(layer)

const MaterialLayer = preload("res://material_layers/material_layer.gd")

func setup_item(tree_item : TreeItem, item : MaterialLayer) -> void:
	tree_item.set_text(0, item.name)


func _on_item_edited():
	# todo: make renaming better
	get_selected().get_metadata(0).name = get_selected().get_text(0)


func _on_item_selected() -> void:
	emit_signal("layer_selected", get_selected().get_metadata(0))
