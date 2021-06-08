extends PopupMenu

"""
The context menu that is shown when right-clicking a layer in the `LayerTree`
"""

var material_layer : MaterialLayer
# warning-ignore:unused_class_variable
var texture_layer : TextureLayer

var _copied_mask : LayerTexture

var texture_layers := [
	FillTextureLayer.new(),
	PaintTextureLayer.new(),
]

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

const PaintTextureLayer = preload("res://material/texture_layer/paint_texture_layer.gd")
const FillTextureLayer = preload("res://material/texture_layer/fill_texture_layer.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const LayerAsset = preload("res://asset/assets/layer_asset.gd")
const JSONTextureLayer = preload("res://material/texture_layer/json_texture_layer.gd")
const LayerTexture = preload("res://material/layer_texture.gd")
const TextureLayer = preload("res://material/texture_layer/texture_layer.gd")

func _on_about_to_show() -> void:
	clear()
	if material_layer:
		if material_layer.mask:
			add_item("Remove Mask", Items.REMOVE_MASK)
			add_item("Copy Mask", Items.COPY_MASK)
		else:
			add_item("Add Empty Mask", Items.ADD_EMPTY_MASK)
			add_item("Add Black Mask", Items.ADD_BLACK_MASK)
			add_item("Add White Mask", Items.ADD_WHITE_MASK)
		add_item("Duplicate", Items.DUPLICATE)
		if _copied_mask:
			add_item("Paste Mask", Items.PASTE_MASK)
		for layer_type in texture_layers:
			add_item("Add %s Layer" % layer_type.get_name(), Items.ADD_LAYER)
			set_item_metadata(get_item_count() - 1, layer_type)
	add_item("Save To Library", Items.SAVE_TO_LIBRARY)


func _on_id_pressed(id : int) -> void:
	match id:
		Items.SAVE_TO_LIBRARY:
			emit_signal("layer_saved")
		Items.ADD_EMPTY_MASK:
			emit_signal("mask_added", LayerTexture.new())
		Items.ADD_BLACK_MASK:
			emit_signal("mask_added", LayerTexture.new())
		Items.ADD_WHITE_MASK:
			emit_signal("mask_added", LayerTexture.new())
		Items.REMOVE_MASK:
			emit_signal("mask_removed")
		Items.COPY_MASK:
			_copied_mask = material_layer.mask.duplicate()
		Items.PASTE_MASK:
			emit_signal("mask_pasted", _copied_mask)
		Items.DUPLICATE:
			emit_signal("duplicated")


func _on_index_pressed(index : int) -> void:
	if get_item_id(index) == Items.ADD_LAYER:
		emit_signal("layer_selected", get_item_metadata(index))


func _on_AssetStore_asset_loaded(asset) -> void:
	if asset is LayerAsset and asset.data is JSONTextureLayer and\
			asset.data.show_in_menu():
		texture_layers.append(asset.data)


func _on_AssetStore_asset_unloaded(asset) -> void:
	if asset is LayerAsset and asset.data in texture_layers:
		texture_layers.erase(asset.data)
