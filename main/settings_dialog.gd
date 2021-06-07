extends ConfirmationDialog

const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")
const KeymapScreen = preload("res://addons/third_party/keymap_screen/keymap_screen.gd")

onready var settings_properties : PropertyPanel = $TabContainer/SettingsProperties
onready var keymap_screen : KeymapScreen = $TabContainer/KeymapScreen
onready var tab_container : TabContainer = $TabContainer

func _ready() -> void:
# warning-ignore:unsafe_property_access
	settings_properties.properties = Settings.settings
	tab_container.set_tab_title(0, "Settings")
	tab_container.set_tab_title(1, "Shortcuts")
	keymap_screen.keymap = {
		File = {
			"New File": "new_file",
			"Open File": "open_file",
			"Save File": "save_file",
			"Save As": "save_as",
		},
		Project = {
			"Export": "export",
			"Load Mesh": "load_mesh",
			"Bake Mesh Maps": "bake_mesh_maps",
		},
		Edit = {
			"Undo": "undo",
			"Redo": "redo",
		},
		Application = {
			"Quit": "quit",
			"Fullscreen": "fullscreen",
			"View Results": "view_results",
			"Settings": "settings",
		},
		About = {
			"About" : "about",
			"Github" : "github",
			"Open Documentation" : "docs",
			"View Licenses" : "licenses",
			"Report Issue" : "issues",
		}
	}


func _on_EditMenuButton_settings_pressed() -> void:
	popup()


func _on_about_to_show() -> void:
	if not Settings.config.has_section("main"):
		return
	for setting in Settings.config.get_section_keys("main"):
		var value = Settings.config.get_value("main", setting)
		if value and settings_properties.has_property(setting):
			settings_properties.set_property_value(setting, value)


func _on_confirmed() -> void:
	var config := ConfigFile.new()
	var values : Dictionary = settings_properties.get_property_values()
	for setting in values:
		config.set_value("main", setting, values[setting])
	Settings.config = config
