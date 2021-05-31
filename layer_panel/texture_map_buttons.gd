extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

var buttons : Dictionary
# warning-ignore:unsafe_property_access
onready var undo_redo : UndoRedo = find_parent("Main").undo_redo

const LayerTexture = preload("res://material/layer_texture.gd")
const MaterialLayer = preload("res://material/material_layer.gd")
const LayerPropertyPanel = preload("res://layer_panel/layer_property_panel.gd")
const LayerMaterial = preload("res://material/layer_material.gd")

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


func _on_LayerTree_layer_selected(layer) -> void:
	if layer is MaterialLayer:
		for button in get_children():
			_silently_set_button_pressed(button, button.name in layer.maps)
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


func _set_map_enabled(on_layer : MaterialLayer, map : String,
		enabled : bool) -> void:
	if enabled:
		on_layer.maps[map] = true
	else:
		on_layer.maps.erase(map)
	
	_silently_set_button_pressed(buttons[map], true)
	on_layer.mark_dirty(true)
	(on_layer.get_layer_material_in() as LayerMaterial).update()
