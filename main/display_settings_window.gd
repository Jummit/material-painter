extends "res://addons/third_party/customizable_ui/window.gd"

const Properties = preload("res://addons/property_panel/properties.gd")
const PropertyPanel = preload("res://addons/property_panel/property_panel.gd")

onready var display_property_panel : PropertyPanel = $DisplayPropertyPanel

func _ready() -> void:
	display_property_panel.set_properties([
		Properties.FloatProperty.new("rotation", 1, 100),
		Properties.FloatProperty.new("exposure", 1, 100),
		Properties.FloatProperty.new("opacity", 1, 100),
		Properties.FloatProperty.new("blur", 1, 100),
		Properties.EnumProperty.new("camera_mode", ["Perspective", "Orthogonal"]),
		Properties.BoolProperty.new("shadows"),
		Properties.StringProperty.new("hdri"),
	])
