extends "res://texture_layers/texture_layer.gd"

func _init(_name := "Untitled Noise Texture"):
	name = _name
	properties.seed = 0
	properties.octaves = 3
	properties.period = 64.0
	properties.persistence = 0.5
	properties.lacunarity = 2.0


func get_properties() -> Array:
	return .get_properties() + [
			Properties.IntProperty.new("seed", 0, 1000),
			Properties.IntProperty.new("octaves", 1, 9),
			Properties.FloatProperty.new("period", 0.1, 256.0),
			Properties.FloatProperty.new("persistence", 0.0, 1.0),
			Properties.FloatProperty.new("lacunarity", 0.1, 4.0),
		]


func generate_texture() -> void:
	var noise := OpenSimplexNoise.new()
	for property in properties:
		if property in noise:
			noise.set(property, properties[property])
	texture = NoiseTexture.new()
	texture.width = int(size.x)
	texture.height = int(size.y)
	texture.noise = noise
