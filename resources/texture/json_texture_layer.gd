extends "res://resources/texture/texture_layer.gd"

"""
A `TextureLayer` that uses a json file to configure the parameters and the shader

It is used in the `EffectAssetType` in the `AssetBrowser`.
"""

export var settings : Dictionary
export var file : String

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

func _init(_file := "").("JSON") -> void:
	if not _file:
		return
	file = _file
	load_data()


func duplicate(_deep := false) -> Resource:
	var dup : Resource = get_script().new()
	dup.settings = settings
	dup.file = file
	dup.data = data
	dup.type_name = type_name
	dup.name = type_name
	return dup


func get_properties() -> Array:
	load_data()
	if not "properties" in data:
		return []
	var list := []
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


func _get_as_shader_layer() -> Layer:
	load_data()
	var layer := Layer.new()
	layer.code = data.shader
	if "properties" in data:
		for property in data.properties:
			if "shader_param" in property and not property.shader_param:
				layer.code = layer.code.format({property.name: settings[property.name]})
			else:
				layer.uniform_types.append(property.type if not property.type\
						in SHADER_TYPES else SHADER_TYPES[property.type])
				layer.uniform_names.append(property.name)
				layer.uniform_values.append(settings[property.name])
	return layer


func load_data() -> void:
	if data:
		return
	var read_file := File.new()
	read_file.open(file, File.READ)
	data = parse_json(read_file.get_as_text())
	read_file.close()
	type_name = data.name
	name = type_name
	if "properties" in data:
		for property in data.properties:
			if property.name in settings:
				continue
			settings[property.name] = DEFAULTS[property.type] if not "default" in\
					property else property.default
