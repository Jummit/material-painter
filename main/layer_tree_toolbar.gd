extends HBoxContainer

const KeymapScreen = preload("res://addons/third_party/keymap_screen/keymap_screen.gd")

onready var keymap_screen : KeymapScreen = $"../../../../../../../../../SettingsDialog/TabContainer/KeymapScreen"
onready var material_option_button : OptionButton = $"../MaterialOptionButton"
onready var add_folder_button : Button = $AddFolderButton
onready var add_layer_button : Button = $AddLayerButton

func _ready() -> void:
	keymap_screen.register_listeners({
		material_option_button : "select_material",
		add_layer_button : "add_layer",
		add_folder_button : "add_folder",
	})


func _on_Main_current_layer_material_changed(_to, _id) -> void:
	for button in get_children():
		if button is Button:
			button.disabled = false
