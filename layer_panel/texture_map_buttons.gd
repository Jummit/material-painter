extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

var buttons : Dictionary
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

# warning-ignore:unused_signal
signal changed(map, enabled)

const LayerTexture = preload("res://resources/texture/layer_texture.gd")
const MaterialLayer = preload("res://resources/material/material_layer.gd")

onready var layer_property_panel : Panel = $"../LayerPropertyPanel"

func _ready() -> void:
	for map in Constants.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = map
		new_button.name = map
		new_button.toggle_mode = true
		buttons[map] = new_button
		new_button.connect("toggled", self, "_on_Button_toggled", [map])
		add_child(new_button)


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is MaterialLayer:
		for button in get_children():
			_silently_set_button_pressed(button, button.name in layer.maps)
		show()
	else:
		hide()


func _on_Button_toggled(button_pressed : bool, map : String) -> void:
	var maps : Dictionary = layer_property_panel.editing_layer.maps
	if button_pressed:
		if not map in maps:
			undo_redo.create_action("Enable Texture Map")
			undo_redo.add_do_method(self, "_set_map_enabled", layer_property_panel.editing_layer, map, true)
			undo_redo.add_undo_method(self, "_set_map_enabled", layer_property_panel.editing_layer, map, false)
			undo_redo.commit_action()
	else:
		undo_redo.create_action("Disable Texture Map")
		undo_redo.add_do_method(self, "_set_map_enabled", layer_property_panel.editing_layer, map, false)
		undo_redo.add_undo_method(self, "_set_map_enabled", layer_property_panel.editing_layer, map, true)
		undo_redo.commit_action()


# block `toggled` signals to avoid emitting the `changed` signal
func _silently_set_button_pressed(button : Button, pressed : bool) -> void:
	button.set_block_signals(true)
	button.pressed = pressed
	button.set_block_signals(false)


func _set_map_enabled(on_layer : MaterialLayer, map : String, enabled : bool) -> void:
	if enabled:
		var new_layer := LayerTexture.new()
		new_layer.parent = on_layer
		on_layer.maps[map] = new_layer
	else:
		on_layer.maps.erase(map)
	
	_silently_set_button_pressed(buttons[map], true)
	on_layer.mark_dirty(true)
	Constants.current_layer_material.update()
	emit_signal("changed", map, enabled)
