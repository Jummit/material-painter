extends "res://property_panel/property_panel.gd"

onready var texture_layer_tree : Tree = $"../TextureLayerTree"

func _on_TextureLayerTree_item_selected():
	self.properties = texture_layer_tree.get_selected().get_metadata(0).get_properties()
