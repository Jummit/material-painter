extends "res://addons/property_panel/property_panel.gd"

const Properties = preload("res://addons/property_panel/properties.gd")

class TextureAssetProperty extends Properties.FilePathProperty:
	func _init(_name : String).(_name):
		pass
	
	func _can_drop_data(_control : Control, data) -> bool:
		return data is Dictionary and "type" in data and data.type == "Textures"
	
	func _drop_data(control : Control, data) -> void:
		_set_value(control, data.asset)

onready var main : Control = $"../../../../../../.."

func _ready():
	set_properties([
		Properties.FloatProperty.new("size", 2, 200),
		Properties.FloatProperty.new("strength", 0.0, 1.0),
		Properties.ColorProperty.new("color"),
		TextureAssetProperty.new("texture"),
		Properties.FloatProperty.new("pattern_scale", 0.0, 4.0),
		Properties.FloatProperty.new("texture_angle", 0.0, 1.0),
		Properties.BoolProperty.new("stamp_mode"),
		TextureAssetProperty.new("texture_mask"),
	])


func _on_ToolButtonContainer_tool_selected(to : int):
	get_parent().visible = to == main.Tools.PAINT
