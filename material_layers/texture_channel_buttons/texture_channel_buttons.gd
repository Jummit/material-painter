extends GridContainer

onready var material_layer_tree : Tree = $"../MaterialLayerTree"

const LayerTexture = preload("res://texture_layers/layer_texture.gd")

signal changed

func _ready():
	for type in Globals.TEXTURE_MAP_TYPES:
		var new_button := Button.new()
		new_button.text = type
		new_button.toggle_mode = true
		new_button.connect("toggled", self, "_on_Button_toggled", [type])
		add_child(new_button)


func _on_Button_toggled(button_pressed : bool, type : String):
	var properties : Dictionary = material_layer_tree.get_selected().get_metadata(0).properties
	if button_pressed:
		properties[type] = null
	else:
		properties.erase(type)
	emit_signal("changed")


func _on_MaterialLayerTree_item_selected():
	var properties : Dictionary = material_layer_tree.get_selected().get_metadata(0).properties
	for button in get_children():
		button.pressed = properties.has(button.name)
