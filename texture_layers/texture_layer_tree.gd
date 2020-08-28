extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"
onready var texture_blending_viewport : Viewport = $"../../../TextureBlendingViewport"
onready var result_texture_rect : TextureRect = $"../../ResultTextureRect"

const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")
const TextureLayer = preload("res://texture_layers/texture_layers.gd").TextureLayer

const ICON_COLUMN := 0
const NAME_COLUMN := 1

func _ready():
	columns = 2
	set_column_expand(ICON_COLUMN, false)
	set_column_min_width(ICON_COLUMN, 32)


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	layers.append(texture_layer)
	texture_layer.generate_texture()
	update_tree()


func _on_TextureLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = texture_layer_property_panel.get_property_values()
	get_selected().get_metadata(0).generate_texture()
	update_icons()
	result_texture_rect.texture = yield(texture_blending_viewport.blend(layers), "completed")


func update_tree():
	.update_tree()
	update_icons()


func update_icons() -> void:
	if not get_root():
		return
	var tree_item := get_root().get_children()
	while true:
		var texture_layer : TextureLayer = tree_item.get_metadata(0)
		var icon := texture_layer.texture
		tree_item.set_icon(ICON_COLUMN, icon)
		tree_item.set_icon_max_width(ICON_COLUMN, 16)
		tree_item = tree_item.get_next_visible()
		if not tree_item:
			break


func _make_custom_tooltip(_for_text : String):
	var tooltip : PanelContainer = load("res://texture_layers/texture_tooltip/texture_tool_tip.tscn").instance()
	tooltip.call_deferred("setup", get_item_at_position(get_local_mouse_position()).get_metadata(0))
	return tooltip


func setup_item(layer_item : TreeItem, layer) -> void:
	layer_item.set_text(NAME_COLUMN, layer.name)
	layer_item.set_editable(NAME_COLUMN, true)


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(NAME_COLUMN)
