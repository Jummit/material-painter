extends "res://addons/property_panel/property_panel.gd"

const TextureLayer = preload("res://texture_layers/texture_layer.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")

class TextureProperty extends "res://addons/property_panel/properties.gd".Property:
	func _init(_name : String).("changed", "selected_texture"):
		name = _name
	
	func _get_control() -> Control:
		return preload("res://texture_option/texture_option.tscn").instance() as Control

func load_texture_layer(texture_layer : TextureLayer) -> void:
	set_properties(texture_layer.get_properties())
	load_values(texture_layer.properties)


func load_material_layer(material_layer : MaterialLayer) -> void:
	# todo: add blend mode
	properties = [
		TextureProperty.new("mask"),
	]
	
	for type in material_layer.get_maps().keys():
		properties.append(TextureProperty.new(type))
	
	set_properties(properties)
	load_values(material_layer.properties)
