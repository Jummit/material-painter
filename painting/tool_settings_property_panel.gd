extends "res://addons/property_panel/property_panel.gd"

const Properties = preload("res://addons/property_panel/properties.gd")

onready var main : Control = $"../../../../../.."

func _ready():
	set_properties([
		Properties.FloatProperty.new("size", 0.5, 50),
		Properties.FloatProperty.new("opacity", 0.0, 1.0),
		Properties.FilePathProperty.new("texture"),
		Properties.ColorProperty.new("color"),
	])


func _on_ToolButtonContainer_tool_selected(to : int):
	visible = to == main.Tools.PAINT
