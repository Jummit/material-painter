extends ConfirmationDialog

func _ready() -> void:
	$SettingsProperties.properties = Settings.settings


func _on_EditMenuButton_settings_pressed() -> void:
	popup()


func _on_about_to_show() -> void:
	if not Settings.config.has_section("main"):
		return
	for setting in Settings.config.get_section_keys("main"):
		var value = Settings.config.get_value("main", setting)
		if value and $SettingsProperties.has_property(setting):
			$SettingsProperties.set_property_value(setting, value)


func _on_confirmed() -> void:
	var config := ConfigFile.new()
	var values : Dictionary = $SettingsProperties.get_property_values()
	for setting in values:
		config.set_value("main", setting, values[setting])
	Settings.config = config
