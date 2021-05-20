extends PopupMenu

"""
The context menu that is shown when right-clicking a layer in the `LayerTree`
"""

var layer
var layer_texture : LayerTexture

var _copied_mask : LayerTexture

var texture_layers := [
	FileTextureLayer.new(),
	BitmapTextureLayer.new(),
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

const MaterialLayer = preload("res://data/material/material_layer.gd")
const MaterialFolder = preload("res://data/material/material_folder.gd")
const LayerTexture = preload("res://data/texture/layer_texture.gd")
const BitmapTextureLayer = preload("res://data/texture/layers/bitmap_texture_layer.gd")
const FileTextureLayer = preload("res://data/texture/layers/file_texture_layer.gd")
const LayerAsset = preload("res://asset_browser/layer_asset.gd")
const JSONTextureLayer = preload("res://data/texture/json_texture_layer.gd")

func _on_about_to_show() -> void:
	clear()
	if layer is MaterialLayer or layer is MaterialFolder:
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
	if layer_texture:
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
			var mask := LayerTexture.new()
			var bitmap := BitmapTextureLayer.new()
			bitmap.parent = mask
			mask.layers.append(bitmap)
			emit_signal("mask_added", mask)
		Items.ADD_WHITE_MASK:
			var bitmap := BitmapTextureLayer.new()
			var mask := LayerTexture.new()
			bitmap.parent = mask
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


func _on_AssetStore_asset_loaded(asset) -> void:
	if asset is LayerAsset and asset.data is JSONTextureLayer and\
			asset.data.data.get("in_context_menu"):
		texture_layers.append(asset.data)


func _on_AssetStore_asset_unloaded(asset) -> void:
	if asset is LayerAsset and asset.data in texture_layers:
		texture_layers.erase(asset.data)
