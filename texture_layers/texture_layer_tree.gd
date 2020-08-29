extends "res://addons/arrangable_tree/arrangable_tree.gd"

onready var texture_layer_property_panel : Panel = $"../TextureLayerPropertyPanel"
onready var texture_blending_viewport : Viewport = $"../../../TextureBlendingViewport"
onready var result_texture_rect : TextureRect = $"../../ResultTextureRect"

const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")
const TextureLayer = preload("res://texture_layers/texture_layers.gd").TextureLayer
const TextureOption = preload("res://texture_option/texture_option.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

const ICON_COLUMN := 0
const NAME_COLUMN := 1

var editing_layer_texture : LayerTexture

func _ready():
	columns = 2
	set_column_expand(ICON_COLUMN, false)
	set_column_min_width(ICON_COLUMN, 32)
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func _make_custom_tooltip(_for_text : String):
	var tooltip : PanelContainer = load("res://texture_layers/texture_tooltip/texture_tool_tip.tscn").instance()
	tooltip.call_deferred("setup", get_item_at_position(get_local_mouse_position()).get_metadata(0))
	return tooltip


func setup_item(tree_item : TreeItem, item : TextureLayer) -> void:
	tree_item.set_text(NAME_COLUMN, item.name)
	tree_item.set_editable(NAME_COLUMN, true)


func load_layer_texture(layer_texture : LayerTexture) -> void:
	# no further setup is needed, as arrays are passed by reference
	self.layers = layer_texture.layers
	update_tree()
	update_result()


func update_tree():
	.update_tree()
	update_icons()


func update_icons() -> void:
	if not get_root():
		return
	var tree_item := get_root().get_children()
	if not tree_item:
		return
	while true:
		var texture_layer : TextureLayer = tree_item.get_metadata(0)
		var icon := texture_layer.texture
		tree_item.set_icon(ICON_COLUMN, icon)
		tree_item.set_icon_max_width(ICON_COLUMN, 16)
		tree_item = tree_item.get_next_visible()
		if not tree_item:
			break


func update_result() -> void:
	var textures := []
	var blend_modes : PoolStringArray = []
	var opacity_values : PoolRealArray = []
	
	for layer in items:
		layer = layer as TextureLayer
		textures.append(layer.texture)
		blend_modes.append(layer.properties.blend_mode)
		opacity_values.append(layer.properties.opacity)
	
	var result : Texture = yield(texture_blending_viewport.blend(textures, blend_modes, opacity_values), "completed")
	result_texture_rect.texture = result
	editing_layer_texture.result = result


func _on_item_edited():
	get_selected().get_metadata(0).name = get_selected().get_text(NAME_COLUMN)


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	items.append(texture_layer)
	texture_layer.generate_texture()
	update_tree()
	update_result()


func _on_TextureLayerPropertyPanel_values_changed():
	get_selected().get_metadata(0).properties = texture_layer_property_panel.get_property_values()
	get_selected().get_metadata(0).generate_texture()
	update_icons()
	update_result()


func _on_TextureOption_selected(texture_option : TextureOption):
	editing_layer_texture = texture_option.selected_texture
	load_layer_texture(editing_layer_texture)
	update_tree()
	update_result()


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])

