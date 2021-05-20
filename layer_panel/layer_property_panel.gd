extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that shows the properties of the selected layer
"""

var editing_layer

onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

const LayerTexture = preload("res://data/texture/layer_texture.gd")
const TextureLayer = preload("res://data/texture/texture_layer.gd")
const MaterialLayer = preload("res://data/material/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")
const JSONTextureLayer = preload("res://data/texture/json_texture_layer.gd")

func _on_LayerTree_layer_selected(layer) -> void:
	editing_layer = layer
	if layer is MaterialLayer:
		properties = []
		
		for type in Constants.TEXTURE_MAP_TYPES if layer.is_folder else layer.maps:
			properties += [
				Properties.EnumProperty.new(type + "/blend_modes",
						Constants.BLEND_MODES, layer.blend_modes[type]),
				Properties.FloatProperty.new(type + "/opacities", 0.0, 1.0,
						layer.opacities[type]),
			]
		
		set_properties(properties)
		load_values(layer)
	elif layer is TextureLayer:
		set_properties(layer.get_properties())
		if layer is JSONTextureLayer:
			load_values(layer.settings)
		else:
			load_values(layer)
	else:
		clear()


func _on_property_changed(property, value) -> void:
	var update_shader = property == "blend_mode"
	var layer = editing_layer
	# don't update the shader if the changed value is a shader parameter
	if layer is JSONTextureLayer:
		for property_data in layer.data.properties:
			if property_data.name == property:
				if "shader_param" in property_data:
					update_shader = not property_data.shader_param
				break
	undo_redo.create_action("Set Layer Property")
	undo_redo.add_do_method(self, "set_value_on_layer", layer, property, value)
	undo_redo.add_do_method(layer, "mark_dirty", update_shader)
	undo_redo.add_do_method(layer.get_layer_material_in(), "update")
	undo_redo.add_undo_method(self, "set_value_on_layer", layer, property,
			layer.get(property))
	undo_redo.add_undo_method(layer, "mark_dirty", update_shader)
	undo_redo.add_undo_method(layer.get_layer_material_in(), "update")
	undo_redo.commit_action()


func set_value_on_layer(layer, property : String, value) -> void:
	if "/" in property:
		layer[property.split("/")[1]][property.split("/")[0]] = value
		layer.mark_dirty("blend_mode" in property)
	elif layer is JSONTextureLayer:
		layer.settings[property] = value
	else:
		layer[property] = value
