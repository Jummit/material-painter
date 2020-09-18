extends "res://addons/property_panel/property_panel.gd"

"""
"""

var editing_layer

const LayerTexture = preload("res://layers/layer_texture.gd")
const TextureLayer = preload("res://layers/texture_layer.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")

class TextureProperty extends "res://addons/property_panel/properties.gd".Property:
	func _init(_name : String).("changed", "selected_texture"):
		name = _name
	
	func _get_control() -> Control:
		return preload("res://texture_option/texture_option.tscn").instance() as Control

func load_texture_layer(texture_layer : TextureLayer) -> void:
	editing_layer = texture_layer
	set_properties(texture_layer.get_properties())
	load_values(texture_layer)


func load_material_layer(material_layer : MaterialLayer) -> void:
	editing_layer = material_layer
	# todo: add blend mode
	properties = [
		TextureProperty.new("mask"),
	]
	
	for type in material_layer.maps.keys():
		properties += [
			TextureProperty.new(type),
			Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES),
			Properties.FloatProperty.new("opacity", 0.0, 1.0),
			]
	
	set_properties(properties)
	load_values(material_layer)
