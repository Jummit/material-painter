extends "res://addons/third_party/customizable_ui/window.gd"

signal changed(to)

const Properties = preload("res://addons/property_panel/properties.gd")
const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")
const HDRIAsset = preload("res://asset/assets/hdri_asset.gd")

onready var display_property_panel : PropertyPanel = $DisplayPropertyPanel

func _ready() -> void:
	display_property_panel.set_properties([
		Properties.FloatProperty.new("rotation", 1, 360*2),
		Properties.FloatProperty.new("exposure", 0.1, 3, 1.0),
		Properties.FloatProperty.new("blur", 1, 20, 1.0),
		Properties.EnumProperty.new("radiance_size", ["32", "64", "128", "256",
				"512", "1024"], "128"),
		Properties.ColorProperty.new("background_color", Color(0.168627,
				0.168627, 0.168627)),
		Properties.EnumProperty.new("camera_mode", ["Perspective", "Orthogonal"]),
		Properties.BoolProperty.new("shadows"),
		Properties.BoolProperty.new("antialiasing"),
		Properties.BoolProperty.new("show_environment"),
		AssetProperty.new("hdri", [HDRIAsset]),
	])


func _on_DisplayPropertyPanel_property_changed(_property, _value) -> void:
	emit_signal("changed", display_property_panel.get_property_values())
