extends "texture_layer.gd"

"""
A `TextureLayer` that uses a json file to configure the parameters and the shader

It is used in the `EffectAssetType` in the `AssetBrowser`.
"""

var file : String setget set_file

var layer_data : Dictionary

const DEFAULTS := {
	int = 0,
	string = "",
	float = 0.0,
	color = Color(),
	bool = true,
}

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	name = data.get("name", "")
	var settings_data : Dictionary = data.get("settings", {})
	for setting in settings_data:
		settings[setting] = str2var(settings_data[setting])
	set_file(data.get("file", ""))


func set_file(to):
	file = to
	if not file:
		return
	var read_file := File.new()
	read_file.open(file, File.READ)
	layer_data = parse_json(read_file.get_as_text())
	read_file.close()
	for property in layer_data.get("properties", []):
		if property.name in settings:
			continue
		var default
		if "default" in property:
			default = property.default
		elif property.type in DEFAULTS:
			default = DEFAULTS[property.type]
		elif property.type == "enum":
			default = property.options.front()
		settings[property.name] = default
	if not name:
		name = get_name()


func show_in_menu() -> bool:
	return layer_data.get("in_context_menu", false)


func serialize() -> Dictionary:
	var data := .serialize()
	data.settings = {}
	for setting in settings:
		data.settings[setting] = var2str(settings[setting])
	data.file = file
	return data


func get_type() -> String:
	return "json"


func get_name() -> String:
	return layer_data.get("name", "JSON")


func get_properties() -> Array:
	var list := []
	if not "properties" in layer_data:
		return list
	for property in layer_data.properties:
		match property.type:
			"float":
				list.append(Properties.FloatProperty.new(property.name,
						property.range[0], property.range[1]))
			"int":
				list.append(Properties.IntProperty.new(property.name,
						property.range[0], property.range[1]))
			"color":
				list.append(Properties.ColorProperty.new(property.name))
			"bool":
				list.append(Properties.BoolProperty.new(property.name))
			"enum":
				list.append(Properties.EnumProperty.new(property.name,
						property.options))
	return list


func get_blending_layer(_context : MaterialGenerationContext,
		map : String) -> Layer:
	var layer : Layer
	if "blends" in layer_data:
		layer = BlendingLayer.new(layer_data.shader,
				blend_modes.get(map, "normal"),
				opacities.get(map, 1.0))
	else:
		layer = Layer.new()
		layer.code = layer_data.shader
	if "properties" in layer_data:
		for property in layer_data.properties:
			if "shader_param" in property and not property.shader_param:
				layer.code = layer.code.format(
						{property.name: settings[property.name]})
			else:
				layer.uniforms[property.name] = settings[property.name]
	return layer