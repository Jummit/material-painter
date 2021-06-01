extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that shows the properties of the selected layer
"""

var editing_layer : Reference

# warning-ignore:unsafe_property_access
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

const TextureLayer = preload("res://material/texture_layer/texture_layer.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")
const JSONTextureLayer = preload("res://material/texture_layer/json_texture_layer.gd")
const LayerMaterial = preload("res://material/layer_material.gd")
const LayerTexture = preload("res://material/layer_texture.gd")

func _on_LayerTree_layer_selected(layer : Reference) -> void:
	editing_layer = layer
	var mat_layer := layer as MaterialLayer
	var tex_layer := layer as TextureLayer
	if mat_layer:
		set_properties(mat_layer.get_properties())
		load_values(mat_layer.settings)
	elif tex_layer:
		set_properties(tex_layer.get_properties())
		load_values(tex_layer.settings)
	else:
		clear()


func _on_property_changed(property : String, value) -> void:
	var update_shader : bool = property == "blend_mode"
	var layer := editing_layer
	# don't update the shader if the changed value is a shader parameter
	var json_layer := layer as JSONTextureLayer
	var mat_layer := layer as MaterialLayer
	var tex_layer := layer as TextureLayer
	var root : LayerMaterial
	var settings : Dictionary
	if mat_layer:
		settings = mat_layer.settings
		root = mat_layer.get_layer_material_in()
	elif tex_layer:
		settings = tex_layer.settings
		root = ((tex_layer.parent as LayerTexture).parent as MaterialLayer)\
				.get_layer_material_in()
	if json_layer:
		for property_data in json_layer.layer_data.properties:
			if property_data.name == property:
				if "shader_param" in property_data:
					update_shader = not property_data.shader_param
				break
	undo_redo.create_action("Set Layer Property")
	undo_redo.add_do_method(self, "set_value_on_layer", layer, property, value)
	undo_redo.add_do_method(layer, "mark_dirty", update_shader)
	undo_redo.add_do_method(root, "update")
	undo_redo.add_undo_method(self, "set_value_on_layer", layer, property,
			settings.get(property))
	undo_redo.add_undo_method(layer, "mark_dirty", update_shader)
	undo_redo.add_undo_method(root, "update")
	undo_redo.commit_action()


func set_value_on_layer(layer : Reference, property : String, value) -> void:
	var mat_layer := layer as MaterialLayer
	var tex_layer := layer as TextureLayer
	if mat_layer:
		mat_layer.settings[property] = value
	elif tex_layer:
		tex_layer.settings[property] = value
