extends PopupMenu

"""
The context menu that is shown when right-clicking a `MaterialLayer`
"""

var layer
var layer_texture_selected : bool

signal layer_selected(layer)
signal layer_saved
signal mask_added
signal mask_removed

enum Items {
	SAVE_TO_LIBRARY,
	ADD_MASK,
	REMOVE_MASK,
	ADD_LAYER,
}

const MaterialLayer = preload("res://resources/material_layer.gd")

func _on_about_to_show() -> void:
	clear()
	add_item("Save To Library", Items.SAVE_TO_LIBRARY)
	if layer is MaterialLayer:
		if layer.mask:
			add_item("Remove Mask", Items.REMOVE_MASK)
		else:
			add_item("Add Mask", Items.ADD_MASK)
	if layer_texture_selected:
		for layer_type in Globals.TEXTURE_LAYER_TYPES:
			add_item("Add %s Layer" % layer_type.new().type_name, Items.ADD_LAYER)
			set_item_metadata(get_item_count() - 1, layer_type)


func _on_id_pressed(id : int) -> void:
	match id:
		Items.SAVE_TO_LIBRARY:
			emit_signal("layer_saved")
		Items.ADD_MASK:
			emit_signal("mask_added")
		Items.REMOVE_MASK:
			emit_signal("mask_removed")


func _on_index_pressed(index : int) -> void:
	if get_item_id(index) == Items.ADD_LAYER:
		emit_signal("layer_selected", get_item_metadata(index))

