extends "texture_layer.gd"

var map_textures : Dictionary

var map_properties := {
	albedo = Properties.ColorProperty,
	normal = Properties.ColorProperty,
	emission = Properties.ColorProperty,
	height = Properties.FloatProperty,
	roughness = Properties.FloatProperty,
	metallic = Properties.FloatProperty,
	ao = Properties.FloatProperty,
}

const Properties = preload("res://addons/property_panel/properties.gd")
const AssetProperty = preload("res://asset/asset_property/property_panel_property.gd")
const TextureAsset = preload("res://asset/assets/texture_asset.gd")

func get_properties() -> Array:
	var properties := []
	for map in enabled_maps:
		if not map in map_textures:
			# Show the grayscale/color property when no map is set.
			var property = map_properties[map]
			if property == Properties.FloatProperty:
				properties.append(property.new(map, 0, 1))
			else:
				properties.append(property.new(map))
		# Always show the texture property even if it isn't set.
		var asset_property := AssetProperty.new(map, [TextureAsset])
		properties.append(asset_property)
	return properties
