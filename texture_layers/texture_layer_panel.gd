extends VBoxContainer

onready var texture_layer_property_panel : Panel = $TextureLayerPropertyPanel
onready var texture_blending_viewport : Viewport = $"../../../TextureBlendingViewport"
onready var texture_layer_tree : Tree = $TextureLayerTree

const TextureLayer = preload("res://texture_layers/texture_layers.gd").TextureLayer
const TextureOption = preload("res://texture_option/texture_option.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

var editing_layer_texture : LayerTexture
var editing_texture : TextureLayer

func _ready():
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func load_layer_texture(layer_texture : LayerTexture) -> void:
	editing_layer_texture = layer_texture
	texture_layer_tree.items = layer_texture.layers
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()


func update_result() -> void:
	var textures := []
	var options := []
	
	for layer in editing_layer_texture.layers:
		layer = layer as TextureLayer
		textures.append(layer.texture)
		options.append({
			blend_mode = layer.properties.blend_mode,
			opacity = layer.properties.opacity,
		})
	
	var result : Texture = yield(texture_blending_viewport.blend(textures, options), "completed")


func _on_TextureLayerTree_item_selected():
	editing_texture = texture_layer_tree.get_selected().get_metadata(0)


func _on_TextureLayerTree_nothing_selected():
	editing_texture = null


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	editing_layer_texture.layers.append(texture_layer)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()
	update_result()


func _on_TextureLayerPropertyPanel_values_changed():
	editing_texture.properties = texture_layer_property_panel.get_property_values()
	update_result()
	texture_layer_tree.update_icons()


func _on_TextureOption_selected(texture_option : TextureOption):
	load_layer_texture(texture_option.selected_texture)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()


func _on_SceneTree_node_added(node : Node):
	if node is TextureOption:
		node.connect("selected", self, "_on_TextureOption_selected", [node])
