extends "res://data/texture/texture_layer.gd"

"""
A `TextureLayer` that uses a json file to configure the parameters and the shader

It is used in the `EffectAssetType` in the `AssetBrowser`.
"""

var settings : Dictionary
var file : String setget set_file

var data : Dictionary

const DEFAULTS := {
	int = 0,
	string = "",
	float = 0.0,
	color = Color(),
	bool = true,
}

const SHADER_TYPES := {
	color = "vec4"
}

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer

func _init(data := {}).(data) -> void:
	settings = data.get("settings", {})
	set_file(data.get("file", ""))


func set_file(to):
	file = to
	if not file:
		return
	var read_file := File.new()
	read_file.open(file, File.READ)
	data = parse_json(read_file.get_as_text())
	read_file.close()
	if "blends" in data:
		settings.blend_mode = "normal"
		settings.opacity = 1.0
	for property in data.get("properties", []):
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


func serialize() -> Dictionary:
	var data := .serialize()
	data.settings = settings
	data.file = file
	return data


func get_type() -> String:
	return "json"


func get_properties() -> Array:
	var list := []
	if "blends" in data:
		list.append(Properties.FloatProperty.new("opacity", 0.0, 1.0, 1.0))
		list.append(Properties.EnumProperty.new("blend_mode",
				Constants.BLEND_MODES))
	if not "properties" in data:
		return list
	for property in data.properties:
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


func _get_as_shader_layer(_context : MaterialGenerationContext) -> Layer:
	var layer : Layer
	if "blends" in data:
		layer = BlendingLayer.new(data.shader, settings.blend_mode,
				settings.opacity)
	else:
		layer = Layer.new()
		layer.code = data.shader
	if "properties" in data:
		for property in data.properties:
			if "shader_param" in property and not property.shader_param:
				layer.code = layer.code.format(
						{property.name: settings[property.name]})
			else:
				layer.uniform_types.append(property.type if not property.type\
						in SHADER_TYPES else SHADER_TYPES[property.type])
				layer.uniform_names.append(property.name)
				layer.uniform_values.append(settings[property.name])
	return layer
 
