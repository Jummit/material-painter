extends PopupMenu

"""
The context menu that is shown when right-clicking a `MaterialLayer`
"""

signal layer_selected(layer)
signal layer_saved
signal mask_added

func _ready() -> void:
	for layer_type in Globals.TEXTURE_LAYER_TYPES:
		add_item("Add %s layer" % layer_type.new().type_name)
		set_item_metadata(get_item_count() - 1, layer_type)


func _on_index_pressed(index : int) -> void:
	match index:
		0:
			emit_signal("layer_saved")
		1:
			emit_signal("mask_added")
		_:
			emit_signal("layer_selected", get_item_metadata(index))
