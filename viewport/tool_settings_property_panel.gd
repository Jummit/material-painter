extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that exposes the settings of the current brush

Only visible when the paint tool is selected.
"""

var painting := false

signal brush_changed(brush)

const Properties = preload("res://addons/property_panel/properties.gd")
const BitmapTextureLayer = preload("res://resources/texture/layers/bitmap_texture_layer.gd")
const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const AssetType = preload("res://asset_browser/asset_classes.gd").AssetType
const TextureAssetType = preload("res://asset_browser/asset_classes.gd").TextureAssetType
const BrushAssetType = preload("res://asset_browser/asset_classes.gd").BrushAssetType
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
	load_values(Brush.new())
	set_property_value("size", 10.0)
	Globals.connect("tool_changed", self, "_on_Globals_tool_changed")


func _update_visibility() -> void:
	get_parent().get_parent().visible = painting and Globals.selected_tool == Globals.Tools.PAINT


func _on_property_changed(_property : String, _value) -> void:
	var new_brush := Brush.new()
	store_values(new_brush)
	new_brush.size = Vector2.ONE * get_property_value("size")
	emit_signal("brush_changed", new_brush)


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset.type is BrushAssetType:
		load_values(asset.data)


func _on_Globals_tool_changed() -> void:
	_update_visibility()


func _on_LayerTree_layer_selected(layer) -> void:
	painting = layer is BitmapTextureLayer
	_update_visibility()


func _on_layout_changed() -> void:
	_update_visibility()
