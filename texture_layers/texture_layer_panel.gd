extends VBoxContainer

onready var texture_layer_property_panel : Panel = $TextureLayerPropertyPanel
onready var texture_layer_tree : Tree = $TextureLayerTree
onready var main : Control = $"../../../.."

const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const LayerTexture = preload("res://texture_layers/layer_texture.gd")

var editing_layer_texture : LayerTexture
var editing_texture_layer : TextureLayer


func load_layer_texture(layer_texture : LayerTexture) -> void:
	editing_layer_texture = layer_texture
	texture_layer_tree.items = layer_texture.layers
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()


func _on_TextureLayerTree_item_selected():
	editing_texture_layer = texture_layer_tree.get_selected().get_metadata(0)
	
	texture_layer_property_panel.properties = editing_texture_layer.get_properties()
	texture_layer_property_panel.load_values(editing_texture_layer.properties)


func _on_TextureLayerTree_nothing_selected():
	if not texture_layer_tree.get_selected():
		editing_texture_layer = null


func _on_TextureCreationDialog_texture_creation_confirmed(texture_layer : TextureLayer):
	editing_layer_texture.layers.append(texture_layer)
	texture_layer_tree.update_tree()
	texture_layer_tree.update_icons()
	main.update_layer_texture(editing_layer_texture)


func _on_TextureLayerPropertyPanel_values_changed():
	editing_texture_layer.properties = texture_layer_property_panel.get_property_values()
	editing_texture_layer.generate_texture()
	texture_layer_tree.update_icons()
	main.update_layer_texture(editing_layer_texture)
