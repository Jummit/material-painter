extends "res://addons/property_panel/property_panel.gd"

const TextureLayer = preload("res://texture_layers/texture_layers.gd").TextureLayer

onready var texture_layer_tree : Tree = $"../TextureLayerTree"

func _on_TextureLayerTree_item_selected():
	var texture_layer : TextureLayer = texture_layer_tree.get_selected().get_metadata(0)
	self.properties = texture_layer.get_properties()
	set_block_signals(true)
	load_values(texture_layer.properties)
	set_block_signals(false)
