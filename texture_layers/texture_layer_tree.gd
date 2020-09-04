extends "res://addons/arrangable_tree/arrangable_tree.gd"

"""
The `ArrangableTree` that represents the layers of the selected LayerTexture

The most left column is used for preview icons.
Hovering over an item shows a `TextureToolTip`.
"""

signal layer_selected(layer)

const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const TextureLayer = preload("res://texture_layers/texture_layer.gd")

const ICON_COLUMN := 0
const NAME_COLUMN := 1

func _ready():
	columns = 2
	set_column_expand(ICON_COLUMN, false)
	set_column_min_width(ICON_COLUMN, 32)


func load_layer_texture(layer_texture : LayerTexture) -> void:
	items = layer_texture.layers
	
	update_tree()
	update_icons()


func setup_item(tree_item : TreeItem, item : TextureLayer) -> void:
	tree_item.set_text(NAME_COLUMN, item.name)
	tree_item.set_editable(NAME_COLUMN, true)


func update_icons() -> void:
	if not get_root():
		return
	var tree_item := get_root().get_children()
	while tree_item:
		var texture_layer : TextureLayer = tree_item.get_metadata(0)
		var icon := texture_layer.texture
		tree_item.set_icon(ICON_COLUMN, icon)
		tree_item.set_icon_max_width(ICON_COLUMN, 16)
		tree_item = tree_item.get_next_visible()


func _make_custom_tooltip(_for_text : String):
	var tooltip : PanelContainer = load("res://texture_layers/texture_tooltip/texture_tool_tip.tscn").instance()
	tooltip.call_deferred("setup", get_item_at_position(get_local_mouse_position()).get_metadata(0))
	return tooltip


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(NAME_COLUMN)


func _on_item_selected() -> void:
	emit_signal("layer_selected", get_selected().get_metadata(0))
