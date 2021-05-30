extends "res://addons/property_panel/properties.gd".Property

var accepted_assets : Array

const AssetProperty = preload("res://asset/asset_property/asset_property.gd")

func _init(_name : String, _accepted_assets : Array, _default := null).(
		"changed", "value", _name, _default):
	accepted_assets = _accepted_assets


func _get_control() -> Control:
	var texture_property : AssetProperty = preload(\
			"asset_property.tscn").instance()
	texture_property.text = name
	texture_property.accepted_assets = accepted_assets
	return texture_property
