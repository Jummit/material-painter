# warning-ignore-all:unused_class_variable

const JsonTextureLayer = preload("res://resources/texture/json_texture_layer.gd")

class Asset:
	var name : String
	var type : AssetType
	var tags : Array
	var file : String
	var preview : Texture
	var data
	
	func get_cached_thumbnail_path() -> String:
		return type.get_cached_thumbnails_path().plus_file(
				file.get_file().get_basename() + ".png")
	
	func get_custom_thumbnail_path() -> String:
		return file.replace("." + file.get_extension(), ".png")


class AssetType:
	var name : String
	var tag : String
	var extension : String
	
	func _init(_name : String, _tag : String, _extension : String) -> void:
		name = _name
		tag = _tag
		extension = _extension
	
	func get_preview(preview_renderer : Node, asset : Asset) -> Texture:
		var cached_thumbnail_path := asset.get_cached_thumbnail_path()
		var custom_thumbnail_path := asset.get_custom_thumbnail_path()
		var dir := Directory.new()
		dir.make_dir_recursive(get_cached_thumbnails_path())
		var preview
		if dir.file_exists(custom_thumbnail_path) and asset.type.extension != "png":
			var preview_image := Image.new()
			preview_image.load(custom_thumbnail_path)
			preview = ImageTexture.new()
			preview.create_from_image(preview_image)
		elif dir.file_exists(cached_thumbnail_path):
			var preview_image := Image.new()
			preview_image.load(cached_thumbnail_path)
			preview = ImageTexture.new()
			preview.create_from_image(preview_image)
		else:
			preview = _generate_preview(preview_renderer, asset)
			if preview is GDScriptFunctionState:
				preview = yield(preview, "completed")
			if preview and preview.get_data():
				preview.get_data().save_png(cached_thumbnail_path)
		return preview
	
	func _generate_preview(_preview_renderer : Node, _asset : Asset) -> Texture:
		return null
	
	func _load(asset : Asset):
		return load(asset.file)
	
	func get_directory() -> String:
		return "user://".plus_file(name.to_lower())
	
	func get_local_directory(project_file : String) -> String:
		return project_file.get_base_dir().plus_file("assets").plus_file(
				name.to_lower())
	
	func get_cached_thumbnails_path() -> String:
		return "user://cached_thumbnails/" + name.to_lower()


class TextureAssetType extends AssetType:
	func _init().("Textures", "texture", "png") -> void:
		pass
	
	func _generate_preview(_preview_renderer : Node, asset) -> Texture:
		var image := Image.new()
		image.load(asset.file)
		image.resize(128, 128)
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	
	func _load(asset : Asset):
		return asset.file


class MaterialAssetType extends AssetType:
	const MaterialLayer = preload("res://resources/material/material_layer.gd")
	const LayerTexture = preload("res://resources/texture/layer_texture.gd")
	const LayerMaterial = preload("res://resources/material/layer_material.gd")
	
	func _init().("Materials", "material", "tres") -> void:
		pass
	
	func _generate_preview(preview_renderer : Node, asset : Asset) -> Texture:
		var material_to_render := LayerMaterial.new()
		material_to_render.add_layer(asset.data, material_to_render, -1,
				false)
		return yield(preview_renderer.get_preview_for_material(material_to_render,
				Vector2(128, 128)), "completed")


class BrushAssetType extends AssetType:
	func _init().("Brushes", "brush", "tres") -> void:
		pass
	
	func _generate_preview(preview_renderer : Node, asset : Asset) -> Texture:
		return yield(preview_renderer.get_preview_for_brush(asset.data,
				Vector2(128, 128)), "completed")


class EffectAssetType extends AssetType:
	func _init().("Effects", "effect", "json") -> void:
		pass
	
	func _load(asset : Asset):
		var layer := JsonTextureLayer.new(asset.file)
		return layer
	
	func _generate_preview(_preview_renderer : Node, _asset : Asset) -> Texture:
		return preload("res://icon.svg")


class HDRAssetType extends AssetType:
	func _init().("HDRIs", "hdris", "hdr") -> void:
		pass
	
	func _generate_preview(preview_renderer : Node, asset) -> Texture:
		return yield(preview_renderer.get_preview_for_hdr(asset.data,
				Vector2(128, 128)), "completed")
	
	func _load(asset : Asset):
		var image := Image.new()
		image.load(asset.file)
		return image
