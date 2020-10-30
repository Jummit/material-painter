extends PopupMenu

"""
The context menu that is shown when right-clicking a `MaterialLayer`
"""

var layer
var layer_texture_selected : bool

var _copied_mask : LayerTexture

signal layer_selected(layer)
signal layer_saved
signal mask_added(mask)
signal mask_pasted(mask)
signal mask_removed
signal duplicated

enum Items {
	SAVE_TO_LIBRARY,
	ADD_EMPTY_MASK,
	ADD_BLACK_MASK,
	ADD_WHITE_MASK,
	REMOVE_MASK,
	ADD_LAYER,
	COPY_MASK,
	PASTE_MASK,
	DUPLICATE,
}

const MaterialLayer = preload("res://resources/material_layer.gd")
const LayerTexture = preload("res://resources/layer_texture.gd")
const BitmapTextureLayer = preload("res://resources/texture_layers/bitmap_texture_layer.gd")

func _on_about_to_show() -> void:
	clear()
	add_item("Save To Library", Items.SAVE_TO_LIBRARY)
	if layer is MaterialLayer:
		if layer.mask:
			add_item("Remove Mask", Items.REMOVE_MASK)
			add_item("Copy Mask", Items.COPY_MASK)
		else:
			add_item("Add Empty Mask", Items.ADD_EMPTY_MASK)
			add_item("Add Black Mask", Items.ADD_BLACK_MASK)
			add_item("Add White Mask", Items.ADD_WHITE_MASK)
		add_item("Duplicate", Items.DUPLICATE)
		if _copied_mask:
			add_item("Paste Mask", Items.PASTE_MASK)
	if layer_texture_selected:
		for layer_type in Globals.TEXTURE_LAYER_TYPES:
			add_item("Add %s Layer" % layer_type.new().type_name, Items.ADD_LAYER)
			set_item_metadata(get_item_count() - 1, layer_type)


func _on_id_pressed(id : int) -> void:
	match id:
		Items.SAVE_TO_LIBRARY:
			emit_signal("layer_saved")
		Items.ADD_EMPTY_MASK:
			emit_signal("mask_added", LayerTexture.new())
		Items.ADD_BLACK_MASK:
			var mask := LayerTexture.new()
			mask.layers.append(BitmapTextureLayer.new())
			emit_signal("mask_added", mask)
		Items.ADD_WHITE_MASK:
			var bitmap := BitmapTextureLayer.new()
			bitmap.image_data.fill(Color.white)
			var mask := LayerTexture.new()
			mask.layers.append(bitmap)
			yield(get_tree(), "idle_frame")
			emit_signal("mask_added", mask)
		Items.REMOVE_MASK:
			emit_signal("mask_removed")
		Items.COPY_MASK:
			_copied_mask = layer.mask
		Items.PASTE_MASK:
			emit_signal("mask_pasted", _copied_mask)
		Items.DUPLICATE:
			emit_signal("duplicated")


func _on_index_pressed(index : int) -> void:
	if get_item_id(index) == Items.ADD_LAYER:
		emit_signal("layer_selected", get_item_metadata(index))
