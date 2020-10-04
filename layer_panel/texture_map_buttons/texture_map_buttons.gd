extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

var buttons : Dictionary

signal changed(map, enabled)

const LayerTexture = preload("res://layers/layer_texture.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")

onready var layer_property_panel : Panel = $"../LayerPropertyPanel"
onready var undo_redo : UndoRedo = $"../../../../..".undo_redo

func _ready() -> void:
	for map in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = map
		new_button.name = map
		new_button.toggle_mode = true
		buttons[map] = new_button
		new_button.connect("toggled", self, "_on_Button_toggled", [map])
		add_child(new_button)


func load_material_layer(material_layer : MaterialLayer) -> void:
	for button in get_children():
		silently_set_button_pressed(button, button.name in material_layer.maps)
	show()


func _on_Button_toggled(button_pressed : bool, map : String) -> void:
	var maps : Dictionary = layer_property_panel.editing_layer.maps
	if button_pressed:
		if not map in maps:
			undo_redo.create_action("Enable Texture Map")
			undo_redo.add_do_method(self, "enable_map", layer_property_panel.editing_layer, map)
			undo_redo.add_undo_method(self, "disable_map", layer_property_panel.editing_layer, map)
			undo_redo.add_undo_method(self, "silently_set_button_pressed", buttons[map], false)
			undo_redo.commit_action()
	else:
		undo_redo.create_action("Disable Texture Map")
		undo_redo.add_do_method(self, "disable_map", layer_property_panel.editing_layer, map)
		undo_redo.add_undo_method(self, "enable_map", layer_property_panel.editing_layer, map)
		undo_redo.add_undo_method(self, "silently_set_button_pressed", buttons[map], true)
		undo_redo.commit_action()
	emit_signal("changed", map, button_pressed)


# block `toggled` signals to avoid emitting the `changed` signal
func silently_set_button_pressed(button : Button, pressed : bool) -> void:
	button.set_block_signals(true)
	button.pressed = pressed
	button.set_block_signals(false)


func enable_map(on_layer : MaterialLayer, map : String) -> void:
	on_layer.maps[map] = LayerTexture.new()


func disable_map(on_layer : MaterialLayer, map : String) -> void:
	on_layer.maps.erase(map)
