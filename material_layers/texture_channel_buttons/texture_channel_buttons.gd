extends GridContainer

onready var material_layer_tree : Tree = $"../MaterialLayerTree"

const LayerTexture = preload("res://texture_layers/layer_texture.gd")

signal changed

func _ready():
	for button in get_children():
		button.connect("toggled", self, "_on_Button_toggled", [button])


func _on_Button_toggled(button_pressed : bool, button : Button):
	var textures : Dictionary = material_layer_tree.get_selected().get_metadata(0).textures
	if button_pressed:
		textures[button.name] = null
	else:
		textures.erase(button.name)
	emit_signal("changed")


func _on_MaterialLayerTree_item_selected():
	var textures : Dictionary = material_layer_tree.get_selected().get_metadata(0).textures
	for button in get_children():
		button.pressed = textures.has(button.name)
