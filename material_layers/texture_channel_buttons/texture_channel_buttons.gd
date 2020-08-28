extends GridContainer

var enabled_textures : Dictionary = {} setget set_enabled_textures

func _ready():
	for button in get_children():
		button.connect("toggled", self, "_on_Button_toggled", [button])


func set_enabled_textures(to):
	enabled_textures = to
	for texture in enabled_textures.keys():
		get_node(texture).pressed = enabled_textures[texture]


func _on_Button_toggled(button_pressed : bool, button : Button):
	enabled_textures[button.name] = button_pressed
