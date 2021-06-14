extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

signal maps_changed

var buttons : Dictionary
# warning-ignore:unsafe_property_access
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

const TextureLayerStack = preload("res://material/texture_layer_stack.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const LayerPropertyPanel = preload("res://layer_panel/layer_property_panel.gd")
const MaterialLayerStack = preload("res://material/material_layer_stack.gd")
const TextureLayer = preload("res://material/texture_layer.gd")

onready var layer_property_panel : LayerPropertyPanel = $"../LayerPropertyPanel"

func _ready() -> void:
	for map in Constants.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = map
		new_button.name = map
		new_button.toggle_mode = true
		buttons[map] = new_button
		new_button.connect("toggled", self, "_on_Button_toggled", [map])
		add_child(new_button)


func _on_LayerTree_layer_selected(layer : Reference) -> void:
	var tex_layer := layer as TextureLayer
	if tex_layer:
		for button in get_children():
			var enabled : bool
			enabled = button.name in tex_layer.enabled_maps
			_silently_set_button_pressed(button, enabled)
		show()
	else:
		hide()


func _on_Button_toggled(button_pressed : bool, map : String) -> void:
	var layer := layer_property_panel.editing_layer
	if button_pressed:
		undo_redo.create_action("Enable Texture Map")
		undo_redo.add_do_method(self, "_set_map_enabled", layer, map, true)
		undo_redo.add_undo_method(self, "_set_map_enabled", layer, map, false)
		undo_redo.commit_action()
	else:
		undo_redo.create_action("Disable Texture Map")
		undo_redo.add_do_method(self, "_set_map_enabled", layer, map, false)
		undo_redo.add_undo_method(self, "_set_map_enabled", layer, map, true)
		undo_redo.commit_action()


# Block `toggled` signals.
func _silently_set_button_pressed(button : Button, pressed : bool) -> void:
	button.set_block_signals(true)
	button.pressed = pressed
	button.set_block_signals(false)


func _set_map_enabled(layer : Reference, map : String, enabled : bool) -> void:
	var tex_layer := layer as TextureLayer
	if not enabled and map in tex_layer.enabled_maps:
		tex_layer.enabled_maps.erase(map)
	elif enabled:
		tex_layer.enabled_maps[map] = true
	tex_layer.mark_dirty(true)
	(((tex_layer.parent as TextureLayerStack).parent as MaterialLayer).\
			get_layer_material_in() as MaterialLayerStack).update()
	
	_silently_set_button_pressed(buttons[map], enabled)
	emit_signal("maps_changed")
