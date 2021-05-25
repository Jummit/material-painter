extends ConfirmationDialog

const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")

onready var settings_properties : PropertyPanel = $SettingsProperties

func _ready() -> void:
# warning-ignore:unsafe_property_access
	settings_properties.properties = Settings.settings


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
