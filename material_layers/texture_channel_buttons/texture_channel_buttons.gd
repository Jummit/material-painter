extends GridContainer

"""
Buttons used to specify the enabled channels of the selected MaterialLayer
"""

onready var material_layer_tree : Tree = $"../MaterialLayerTree"

const LayerTexture = preload("res://texture_layers/layer_texture.gd")
const MaterialLayer = preload("res://material_layers/material_layer.gd")

signal changed

func _ready():
	for type in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = type
		new_button.name = type
		new_button.toggle_mode = true
		new_button.connect("toggled", self, "_on_Button_toggled", [type])
		add_child(new_button)


func _on_Button_toggled(button_pressed : bool, type : String):
	var properties : Dictionary = material_layer_tree.get_selected().get_metadata(0).properties
	if button_pressed:
		if not properties.has(type):
			properties[type] = null
	else:
		properties.erase(type)
	emit_signal("changed")


func _on_MaterialLayerTree_layer_selected(material_layer : MaterialLayer):
	var properties : Dictionary = material_layer.properties
	for button in get_children():
		# block `toggled` signals to avoid emitting the `changed` signal
		button.set_block_signals(true)
		button.pressed = properties.has(button.name)
		button.set_block_signals(false)
