extends "res://resources/texture/texture_layer.gd"

export var settings := {}
export var type : String

var data : Dictionary

const Properties = preload("res://addons/property_panel/properties.gd")

func _init().("JSON") -> void:
	var file := File.new()
	file.open(type, File.READ)
	data = parse_json(file.get_as_text())
	file.close()
	type_name = data.name


func get_properties() -> Array:
	if not "properties" in data:
		return []
	var list := []
	for property in data.properties:
		match property.type:
			"float":
				list.append(Properties.FloatProperty.new(property.name,
						properties.range[0], properties.range[1]))
			"int":
				list.append(Properties.IntProperty.new(property.name,
						properties.range[0], properties.range[1]))
			"color":
				list.append(Properties.ColorProperty.new(property.name))
			"bool":
				list.append(Properties.BoolProperty.new(property.name))
			"enum":
				list.append(Properties.EnumProperty.new(property.options,
						property.name))
	return list


func _get_as_shader_layer() -> Layer:
	var layer := Layer.new()
	layer.code = data.shader
	if "properties" in data:
		for property in data.properties:
			if "shader_param" in property and not property.shader_param:
				layer.code.format({property.name: settings[property.name]})
			else:
				layer.uniform_types.append(property.type)
				layer.uniform_names.append(property.name)
				layer.uniform_values.append(settings[property.name])
	return layer
