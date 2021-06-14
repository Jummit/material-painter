extends "res://addons/property_panel/property_panel.gd"

"""
The `PropertyPanel` that exposes the settings of the current brush

Only visible when the paint tool is selected.
"""

var selected_tool : int = Constants.Tools.PAINT
var painting := false

signal brush_changed(brush)

const Properties = preload("res://addons/property_panel/properties.gd")
const Asset = preload("res://asset/assets/asset.gd")
const BrushAsset = preload("res://asset/assets/brush_asset.gd")
const Brush = preload("res://main/brush.gd")
const PaintTextureLayer = preload("res://material/paint_texture_layer.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")

func _ready() -> void:
	set_properties([
		Properties.FloatProperty.new("size", 2, 100),
		Properties.FloatProperty.new("strength", 0.0, 1.0),
		Properties.ColorProperty.new("color"),
		AssetProperty.new("texture", [TextureAsset]),
		Properties.FloatProperty.new("pattern_scale", 0.0, 4.0),
		Properties.FloatProperty.new("texture_angle", 0.0, 1.0),
		Properties.BoolProperty.new("stamp_mode"),
		AssetProperty.new("texture_mask", [TextureAsset]),
	])
	load_values(Brush.new())


func _update_visibility() -> void:
	(get_parent().get_parent() as CanvasItem).visible = painting and\
			selected_tool == Constants.Tools.PAINT


func _on_property_changed(_property : String, _value) -> void:
	var new_brush := Brush.new()
	store_values(new_brush)
	emit_signal("brush_changed", new_brush)


func _on_AssetBrowser_asset_activated(asset : Asset) -> void:
	if asset is BrushAsset:
		load_values(asset.data)


func _on_LayerTree_layer_selected(layer) -> void:
	painting = layer is PaintTextureLayer
	_update_visibility()


func _on_layout_changed(_meta) -> void:
	_update_visibility()


func _on_Main_selected_tool_changed(to : int) -> void:
	selected_tool = to
	_update_visibility()
