extends "res://addons/property_panel/properties.gd".Property

var accepted_assets : Array

const AssetProperty = preload("res://asset/asset_property/asset_property.gd")

func _init(_name : String, _accepted_assets : Array, _default := null).(
		"changed", "value", _name, _default):
	accepted_assets = _accepted_assets


func _get_control() -> Control:
	var asset_property : AssetProperty = preload(\
			"asset_property.tscn").instance()
	asset_property.text = name
	asset_property.allowed_assets = accepted_assets
	return asset_property


func _can_drop_data(_control : Control, data) -> bool:
	for type in accepted_assets:
		if data is type:
			return true
	return false


func _drop_data(control : Control, data) -> void:
	_set_value(control, data)
