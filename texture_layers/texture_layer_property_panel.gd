extends "res://addons/property_panel/property_panel.gd"

const TextureLayerTree = preload("texture_layer_tree.gd")

onready var texture_layer_tree : Tree = $"../TextureLayerTree"

func _on_TextureLayerTree_item_selected():
	var texture_layer : TextureLayerTree.TextureLayer = texture_layer_tree.get_selected().get_metadata(0)
	self.properties = texture_layer.get_properties()
	load_values(texture_layer.properties)
