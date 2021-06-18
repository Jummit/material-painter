extends Reference

static func load_layer(data : Dictionary) -> Reference:
	var types := {
		"paint": preload("paint_texture_layer.gd"),
		"fill": preload("fill_texture_layer.gd"),
		"effect": preload("effect_texture_layer.gd"),
	}
	return types[data.type].new(data)
