static func parse_material_library(path : String) -> Dictionary:
	var file := File.new()
	var error := file.open(path, File.READ)
	if error != OK:
		return {}
	
	var materials := {}

	var current_material := SpatialMaterial.new()
	var current_name : String
	
	while true:
		var line := file.get_line()
		var split := line.split(" ")
		match split[0]:
			"newmtl":
				current_name = split[1]
				current_material = SpatialMaterial.new()
				current_material.resource_name = current_name
				materials[current_name] = current_material
			"Kd":
				current_material.albedo_color = Color(float(split[1]),
						float(split[2]), float(split[3]))
			"Ks":
				current_material.metallic = max(max(float(split[1]),
						float(split[2])), float(split[3]))
			"Ns":
				current_material.metallic = (1000.0 - float(split[1])) / 1000.0
			"d":
				current_material.albedo_color.a = float(split[1])
				if current_material.albedo_color.a < 0.99:
					current_material.flags_transparent = true
			"Tr":
				current_material.albedo_color.a = 1.0 - float(split[1])
				if current_material.albedo_color.a < 0.99:
					current_material.flags_transparent = true
			"map_Kd":
				current_material.albedo_texture = _get_texture(path, split[1])
			"map_Ks":
				current_material.metallic_texture = _get_texture(path, split[1])
			"map_Ns":
				current_material.roughness_texture = _get_texture(path, split[1])
			"map_bump":
				current_material.normal_enabled = true
				current_material.normal_texture = _get_texture(path, split[1])
		if file.eof_reached():
			break
	
	return materials


static func _get_texture(mtl_file : String,
		texture_file : String) -> ImageTexture:
	var texture_path := mtl_file.get_base_dir().plus_file(texture_file)
	var image := Image.new()
	if image.load(texture_path) != OK:
		return null
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture
