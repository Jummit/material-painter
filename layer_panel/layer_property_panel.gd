extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that shows the properties of the selected layer
"""

var editing_layer

const LayerTexture = preload("res://resources/layer_texture.gd")
const TextureLayer = preload("res://resources/texture_layer.gd")
const MaterialLayer = preload("res://resources/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")

func load_texture_layer(texture_layer : TextureLayer) -> void:
	editing_layer = texture_layer
	set_properties(texture_layer.get_properties())
	load_values(texture_layer)


func load_material_layer(material_layer : MaterialLayer) -> void:
	editing_layer = material_layer
	# todo: add blend mode
	properties = []
	
	for type in material_layer.maps.keys():
		properties += [
			Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES),
			Properties.FloatProperty.new("opacity", 0.0, 1.0),
			]
	
	set_properties(properties)
	load_values(material_layer)


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	load_texture_layer(texture_layer)


func _on_LayerTree_material_layer_selected(material_layer) -> void:
	load_material_layer(material_layer)
