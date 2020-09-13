extends GridContainer

"""
Buttons used to specify the enabled channels of the selected `MaterialLayer`
"""

signal changed

const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")

onready var layer_tree : Tree = $"../LayerTree"

func _ready():
	for type in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = type
		new_button.name = type
		new_button.toggle_mode = true
		new_button.connect("toggled", self, "_on_Button_toggled", [type])
		add_child(new_button)


func _on_Button_toggled(button_pressed : bool, type : String):
	var properties : Dictionary = layer_tree.get_selected().get_meta("layer").properties
	if button_pressed:
		if not properties.has(type):
			properties[type] = LayerTexture.new()
	else:
		properties.erase(type)
	emit_signal("changed")


func _on_LayerTree_material_layer_selected(material_layer : MaterialLayer) -> void:
	show()
	var properties : Dictionary = material_layer.properties
	for button in get_children():
		# block `toggled` signals to avoid emitting the `changed` signal
		button.set_block_signals(true)
		button.pressed = properties.has(button.name)
		button.set_block_signals(false)
