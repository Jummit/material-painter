extends "res://addons/property_panel/property_panel.gd"

const Properties = preload("res://addons/property_panel/properties.gd")

onready var main : Control = $"../../../../../.."

func _ready():
	set_properties([
		Properties.FloatProperty.new("size", 0.0, 0.5),
		Properties.FloatProperty.new("strength", 0.0, 1.0),
		Properties.ColorProperty.new("color"),
		Properties.FilePathProperty.new("texture"),
		Properties.FloatProperty.new("pattern_scale", 0.0, 1.0),
		Properties.FloatProperty.new("texture_angle", 0.0, 1.0),
		Properties.BoolProperty.new("stamp_mode"),
		Properties.FilePathProperty.new("texture_mask"),
	])


func _on_ToolButtonContainer_tool_selected(to : int):
	visible = to == main.Tools.PAINT
