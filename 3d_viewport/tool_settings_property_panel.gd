extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that exposes the settings of the current brush

Only visible when the paint tool is selected.
"""

var correct_tool_selected := false

const Properties = preload("res://addons/property_panel/properties.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://main/asset_browser.gd").Asset
const TextureAssetType = preload("res://main/asset_browser.gd").TextureAssetType

class TextureAssetProperty extends Properties.FilePathProperty:
	func _init(_name : String).(_name):
		pass
	
	func _can_drop_data(_control : Control, data) -> bool:
		return data is Asset and data.type is TextureAssetType
	
	func _drop_data(control : Control, data) -> void:
		_set_value(control, data.data)

onready var Tools : Dictionary = $"../../../HBoxContainer/Window/ToolButtonContainer".Tools

func _ready() -> void:
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


func _on_ToolButtonContainer_tool_selected(to : int) -> void:
	correct_tool_selected = to == Tools.PAINT
	get_parent().get_parent().visible = correct_tool_selected


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	if texture_layer is BitmapTextureLayer:
		get_parent().get_parent().visible = correct_tool_selected


func _on_LayerTree_material_layer_selected(_material_layer) -> void:
	get_parent().get_parent().hide()


func _on_LayerTree_folder_layer_selected() -> void:
	get_parent().hide()
