const Properties = preload("res://addons/property_panel/properties.gd")

class TextureLayer:
	# warning-ignore:unused_class_variable
	var name : String
	var properties : Dictionary
	var texture : Texture setget , get_texture
	
	func get_properties() -> Array:
		return [
			Properties.FloatProperty.new("opacity", 0.0, 1.0),
			Properties.EnumProperty.new("blend_mode", Globals.BLEND_MODES)]
	
	func get_texture():
		if not texture:
			print("Getting a texture, generating it")
			generate_texture()
		return texture
	
	func generate_texture():
		return null
	
	func _init():
		properties = {
			opacity = 1.0,
			blend_mode = "normal"
		}

class ScalarTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties.value = .5
	
	func get_properties() -> Array:
		return .get_properties() + [Properties.FloatProperty.new("value", 0.0, 1.0)]
	
	func generate_texture():
		var image := Image.new()
		image.create(1028, 1028, false, Image.FORMAT_RGB8)
		image.fill(Color.black.lightened(properties.value))
		texture = ImageTexture.new()
		texture.create_from_image(image)

class ColorTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties.color = Color()
	
	func get_properties() -> Array:
		return .get_properties() + [Properties.ColorProperty.new("color")]
	
	func generate_texture():
		var image := Image.new()
		image.create(1028, 1028, false, Image.FORMAT_RGB8)
		image.fill(properties.color)
		texture = ImageTexture.new()
		texture.create_from_image(image)

class BitmapTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties.image_path = ""
	
	func get_properties() -> Array:
		return .get_properties() + [Properties.FilePathProperty.new("image_path")]
	
	func generate_texture():
		if ResourceLoader.exists(properties.image_path, "Texture"):
			var image := Image.new()
			if image.load(properties.image_path) == OK:
				texture = ImageTexture.new()
				texture.create_from_image(image)

class NoiseTextureLayer extends TextureLayer:
	func _init(_name : String):
		name = _name
		properties.noise_seed = 0
		properties.octaves = 3
		properties.period = 64.0
		properties.persistence = 0.5
		properties.lacunarity = 2.0
	
	func get_properties() -> Array:
		return .get_properties() + [
				Properties.IntProperty.new("noise_seed", 0, 1000),
				Properties.IntProperty.new("octaves", 1, 9),
				Properties.FloatProperty.new("period", 0.1, 256.0),
				Properties.FloatProperty.new("persistence", 0.0, 1.0),
				Properties.FloatProperty.new("lacunarity", 0.1, 4.0),
			]
	
	func generate_texture():
		var noise := OpenSimplexNoise.new()
		noise.seed = properties.noise_seed
		noise.octaves = properties.octaves
		noise.period = properties.period
		noise.persistence = properties.persistence
		noise.lacunarity = properties.lacunarity
		texture = NoiseTexture.new()
		texture.noise = noise
