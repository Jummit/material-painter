extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that exposes the settings of the current brush

Only visible when the paint tool is selected.
"""

var correct_tool_selected := false

signal brush_changed(brush)

const Properties = preload("res://addons/property_panel/properties.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://main/asset_browser.gd").Asset
const TextureAssetType = preload("res://main/asset_browser.gd").TextureAssetType
const BrushAssetType = preload("res://main/asset_browser.gd").BrushAssetType
const Brush = preload("res://addons/painter/brush.gd")

class TextureAssetProperty extends Properties.FilePathProperty:
	func _init(_name : String).(_name):
		pass
	
	func _can_drop_data(_control : Control, data) -> bool:
		return data is Asset and data.type is TextureAssetType
	
	func _drop_data(control : Control, data) -> void:
		_set_value(control, data.data)

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
	if ProjectSettings.get_setting("application/config/initialize_painter"):
		load_values(Brush.new())
		set_property_value("size", 10.0)


func _on_ToolButtonContainer_tool_selected(to : int) -> void:
	correct_tool_selected = to == Globals.Tools.PAINT
	get_parent().get_parent().visible = correct_tool_selected


func _on_LayerTree_texture_layer_selected(texture_layer) -> void:
	if texture_layer is BitmapTextureLayer:
		get_parent().get_parent().visible = correct_tool_selected


func _on_LayerTree_material_layer_selected(_material_layer) -> void:
	get_parent().get_parent().hide()


func _on_LayerTree_folder_layer_selected() -> void:
	get_parent().hide()


func _on_property_changed(_property : String, _value):
	var new_brush := Brush.new()
	store_values(new_brush)
	new_brush.size = Vector2.ONE * get_property_value("size")
	emit_signal("brush_changed", new_brush)


func _on_AssetBrowser_asset_activated(asset):
	if asset.type is BrushAssetType:
		load_values(asset.data)
