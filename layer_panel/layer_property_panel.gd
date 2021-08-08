extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that shows the properties of the selected layer
"""

var editing_layer : Reference setget set_editing_layer

# warning-ignore:unsafe_property_access
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

const TextureLayer = preload("res://material/texture_layer.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const Properties = preload("res://addons/property_panel/properties.gd")
const EffectTextureLayer = preload("res://material/effect_texture_layer.gd")
const MaterialLayerStack = preload("res://material/material_layer_stack.gd")
const TextureLayerStack = preload("res://material/texture_layer_stack.gd")

const NULL_VALUE := 10101010101010

func _on_LayerTree_layer_selected(layer : Reference) -> void:
	var mat_layer := layer as MaterialLayer
	var tex_layer := layer as TextureLayer
	if mat_layer and mat_layer.hide_first_layer:
		set_editing_layer(mat_layer.main.layers.front())
	elif tex_layer:
		set_editing_layer(layer)


func set_editing_layer(layer : Reference) -> void:
	editing_layer = layer
	var tex_layer := layer as TextureLayer
	if tex_layer:
		set_properties(tex_layer.get_properties())
		load_values(tex_layer)
	else:
		clear()


func _on_property_changed(property : String, value) -> void:
	var update_shader := false
	var layer := editing_layer
	# don't update the shader if the changed value is a shader parameter
	var mat_layer := layer as MaterialLayer
	var tex_layer := layer as TextureLayer
	if mat_layer:
		tex_layer = mat_layer.layers.front()
	var root : MaterialLayerStack
	root = ((tex_layer.parent as TextureLayerStack).parent as MaterialLayer)\
			.get_layer_material_in()
	var effect_layer := tex_layer as EffectTextureLayer
	if effect_layer:
		update_shader = effect_layer.does_property_update_shader(property)
	undo_redo.create_action("Set Layer Property")
	if value == null:
		value = NULL_VALUE
	undo_redo.add_do_method(self, "set_value_on_layer", tex_layer, property,
			value)
	undo_redo.add_do_method(tex_layer, "mark_dirty", update_shader)
	undo_redo.add_do_method(root, "update")
	undo_redo.add_undo_method(self, "set_value_on_layer", tex_layer, property,
			tex_layer.get(property))
	undo_redo.add_undo_method(tex_layer, "mark_dirty", update_shader)
	undo_redo.add_undo_method(root, "update")
	undo_redo.commit_action()
#	if tex_layer.get_properties().size() != properties.size():
#		yield(get_tree(), "idle_frame")
#		set_properties(tex_layer.get_properties())
#		load_values(tex_layer)


func set_value_on_layer(layer : TextureLayer, property : String, value) -> void:
	if value is int and value == NULL_VALUE:
		value = null
	layer.set_property(property, value)


func _on_TextureMapButtons_maps_changed() -> void:
	set_editing_layer(editing_layer)
