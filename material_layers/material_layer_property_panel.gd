extends "res://addons/property_panel/property_panel.gd"

onready var material_layer_tree : Tree = $"../MaterialLayerTree"
onready var texture_channel_buttons : GridContainer = $"../TextureChannelButtons"

const MaterialLayer = preload("res://material_layers/material_layer_tree.gd").MaterialLayer

# Godot Engine bug: can't use parent class directly
class TextureProperty extends "res://addons/property_panel/property_panel.gd".Property:
	func _init(_name : String).("changed", "selected_texture"):
		name = _name
	
	func get_control() -> Control:
		return preload("res://texture_option/texture_option.tscn").instance() as Control


func _on_MaterialLayerTree_item_selected():
	var material_layer : MaterialLayer = material_layer_tree.get_selected().get_metadata(0)
	self.properties = [
		FloatProperty.new("opacity", 0.0, 1.0),
		TextureProperty.new("mask"),
	]
	for texture in texture_channel_buttons.enabled_textures.keys():
		if texture_channel_buttons.enabled_textures[texture]:
			properties.append(TextureProperty.new(texture))
