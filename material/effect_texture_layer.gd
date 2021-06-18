extends "texture_layer.gd"

"""
A `TextureLayer` that uses a json file to configure the parameters and the shader

It is used in the `EffectAssetType` in the `AssetBrowser`.
"""

var effect : EffectAsset
var effect_data : Dictionary

const DEFAULTS := {
	int = 0,
	string = "",
	float = 0.0,
	color = Color(),
	bool = true,
}

const Properties = preload("res://addons/property_panel/properties.gd")
const BlendingLayer = preload("res://addons/layer_blending_viewport/layer_blending_viewport.gd").BlendingLayer
const EffectAsset = preload("res://asset/assets/effect_asset.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")

func _init(data := {}).(data) -> void:
	name = data.get("name", "")
	if data.get("file"):
		set_effect(EffectAsset.new(data.get("file", "")))


func set_settings(to : Dictionary) -> void:
	settings = to
	if to.effect != effect:
		set_effect(to.effect)


func set_effect(to):
	effect = to
	if not effect:
		return
# warning-ignore:unsafe_property_access
	effect_data = effect.data
# warning-ignore:unsafe_property_access
	for property in effect_data.get("properties", []):
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


func serialize() -> Dictionary:
	var data := .serialize()
	if effect:
		data.file = effect.path
	return data


func get_type() -> String:
	return "effect"


func get_name() -> String:
	return effect_data.get("name", "Effect")


func get_properties() -> Array:
	var list := [
		AssetProperty.new("effect", [EffectAsset])
	]
	if not "properties" in effect_data:
		return list
	for property in effect_data.properties:
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
	if not effect_data.get("shader"):
		return null
	if "blends" in effect_data:
		layer = BlendingLayer.new(effect_data.shader,
				blend_modes.get(map, "normal"),
				opacities.get(map, 1.0))
	else:
		layer = Layer.new()
		layer.code = effect_data.shader
	if "properties" in effect_data:
		for property in effect_data.properties:
			if "shader_param" in property and not property.shader_param:
				layer.code = layer.code.format(
						{property.name: settings[property.name]})
			else:
				layer.uniforms[property.name] = settings[property.name]
	return layer


func does_property_update_shader(property : String) -> bool:
	for property_data in effect_data.get("properties", []):
		if property_data.get("name") == property:
			if "shader_param" in property_data:
				return true
	return false
