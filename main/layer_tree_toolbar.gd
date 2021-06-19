extends HBoxContainer

const KeymapScreen = preload("res://addons/third_party/keymap_screen/keymap_screen.gd")

onready var keymap_screen : KeymapScreen = $"../../../../../../../../../SettingsDialog/TabContainer/KeymapScreen"
onready var map_option_button : OptionButton = $MapOptionButton
onready var add_folder_button : Button = $AddFolderButton
onready var add_fill_layer_button : Button = $AddFillLayerButton
onready var add_paint_layer_button : Button = $AddPaintLayerButton
onready var add_layer_button : Button = $AddLayerButton

func _ready() -> void:
	keymap_screen.register_listeners({
		map_option_button : "select_map",
		add_fill_layer_button : "add_fill",
		add_paint_layer_button : "add_paint",
		add_layer_button : "add_layer",
		add_folder_button : "add_folder",
	})
