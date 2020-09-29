extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

signal changed(map, enabled)

const LayerTexture = preload("res://layers/layer_texture.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")

onready var layer_property_panel : Panel = $"../LayerPropertyPanel"

func _ready() -> void:
	for map in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = map
		new_button.name = map
		new_button.toggle_mode = true
		new_button.connect("toggled", self, "_on_Button_toggled", [map])
		add_child(new_button)


func load_material_layer(material_layer : MaterialLayer) -> void:
	for button in get_children():
		# block `toggled` signals to avoid emitting the `changed` signal
		button.set_block_signals(true)
		button.pressed = button.name in material_layer.maps
		button.set_block_signals(false)
	show()


func _on_Button_toggled(button_pressed : bool, map : String) -> void:
	var maps : Dictionary = layer_property_panel.editing_layer.maps
	if button_pressed:
		if not map in maps:
			maps[map] = LayerTexture.new()
	else:
		maps.erase(map)
	emit_signal("changed", map, button_pressed)
