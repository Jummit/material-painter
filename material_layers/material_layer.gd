extends Resource

"""
A single layer of a `LayerMaterial`

The `properties` `Dictionary` holds a `mask` that is used when blending the layers
and can hold a `LayerTexture` for each map (for example albedo, height, etc...).
"""

# warning-ignore-all:unused_class_variable
export var properties : Dictionary
export var name := "Untitled Layer"
export var opacity := 1.0
export var blend_mode := "normal"
export var visible := true

func get_maps() -> Dictionary:
	var maps := {}
	for map_type in Globals.TEXTURE_MAP_TYPES:
		if map_type in properties:
			maps[map_type] = properties[map_type]
	return maps
