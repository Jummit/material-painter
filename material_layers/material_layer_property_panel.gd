extends "res://addons/property_panel/property_panel.gd"

onready var material_layer_tree : Tree = $"../MaterialLayerTree"
onready var texture_channel_buttons : GridContainer = $"../TextureChannelButtons"

const MaterialLayer = preload("res://material_layers/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")

class TextureProperty extends "res://addons/property_panel/properties.gd".Property:
	func _init(_name : String).("changed", "selected_texture"):
		name = _name
	
	func get_control() -> Control:
		return preload("res://texture_option/texture_option.tscn").instance() as Control


func _on_MaterialLayerTree_item_selected():
	build_properties(material_layer_tree.get_selected().get_metadata(0))


func build_properties(material_layer : MaterialLayer) -> void:
	properties = [
		Properties.FloatProperty.new("opacity", 0.0, 1.0),
		TextureProperty.new("mask"),
	]
	
	for type in Globals.TEXTURE_MAP_TYPES:
		if material_layer.properties.has(type):
			properties.append(TextureProperty.new(type))
	set_properties(properties)
	load_values(material_layer.properties)


func _on_TextureChannelButtons_changed():
	build_properties(material_layer_tree.get_selected().get_metadata(0))
