extends GridContainer

"""
Buttons used to specify the enabled maps of the selected `MaterialLayer`
"""

signal changed(map, activated)

const LayerTexture = preload("res://layers/layer_texture.gd")
const MaterialLayer = preload("res://layers/material_layer.gd")

onready var layer_property_panel : Panel = $"../LayerPropertyPanel"

func _ready():
	for type in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = type
		new_button.name = type
		new_button.toggle_mode = true
		new_button.connect("toggled", self, "_on_Button_toggled", [type])
		add_child(new_button)


func load_material_layer(material_layer : MaterialLayer) -> void:
	show()
	for button in get_children():
		# block `toggled` signals to avoid emitting the `changed` signal
		button.set_block_signals(true)
		button.pressed = button.name in material_layer.maps
		button.set_block_signals(false)


func _on_Button_toggled(button_pressed : bool, type : String):
	var maps : Dictionary = layer_property_panel.editing_layer.maps
	if button_pressed:
		if not type in maps:
			maps[type] = LayerTexture.new()
	else:
		maps.erase(type)
	emit_signal("changed", type, button_pressed)
