extends HBoxContainer

"""
A list of assets that can be drag and dropped onto different UI elements

The tabs for each `AssetType` are generated procedurally.
Each `AssetType` defines how to load the asset file
and how to generate a thumbnail for it.
"""

signal asset_activated(asset)

var current_tag := "all"
var tags : PoolStringArray = ["all", "texture", "material", "brush"]
var tagged_assets := {}

var ASSET_TYPES := {
	TEXTURE = TextureAssetType.new(),
#	MATERIAL = MaterialAssetType.new(),
#	BRUSH = BrushAssetType.new(),
}

onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : ItemList = $VBoxContainer2/AssetList
onready var search_edit : LineEdit = $VBoxContainer2/SearchEdit
onready var tag_list : Tree = $VBoxContainer/TagList

class AssetType:
	var name : String
	var tag : String
	
	func _init(_name : String, _tag : String) -> void:
		name = _name
		tag = _tag
	
	func get_preview(asset : Asset) -> Texture:
		var cache_thumbnail_path := get_cached_thumbnails_path().plus_file(asset.file.get_file().get_basename() + ".png")
		var dir := Directory.new()
		dir.make_dir_recursive(get_cached_thumbnails_path())
		var preview
		if dir.file_exists(cache_thumbnail_path):
			var preview_image := Image.new()
			preview_image.load(cache_thumbnail_path)
			preview = ImageTexture.new()
			preview.create_from_image(preview_image)
		else:
			preview = _generate_preview(asset)
			if preview is GDScriptFunctionState:
				preview = yield(preview, "completed")
			preview.get_data().save_png(cache_thumbnail_path)
		return preview
	
	func _generate_preview(_asset : Asset) -> Texture:
		return null
	
	func _load(asset : Asset):
		return load(asset.file)
	
	func get_asset_directory() -> String:
		return "user://".plus_file(name.to_lower())
	
	func get_cached_thumbnails_path() -> String:
		return "user://cached_thumbnails/" + name.to_lower()

class TextureAssetType extends AssetType:
	func _init().("Textures", "texture") -> void:
		pass
	
	func _generate_preview(asset) -> Texture:
		var image := Image.new()
		image.load(asset.file)
		image.resize(128, 128)
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	
	func _load(asset : Asset):
		return asset.file

class MaterialAssetType extends AssetType:
	const MaterialLayer = preload("res://resources/material_layer.gd")
	const LayerTexture = preload("res://resources/layer_texture.gd")
	const LayerMaterial = preload("res://resources/layer_material.gd")
	
	func _init().("Materials", "material") -> void:
		pass
	
	func _generate_preview(asset : Asset) -> Texture:
		var material_to_render := LayerMaterial.new()
		material_to_render.layers.append(asset.data)
		return yield(PreviewRenderer.get_preview_for_material(material_to_render, Vector2(128, 128)), "completed")

class BrushAssetType extends AssetType:
	func _init().("Brushes", "brush") -> void:
		pass
	
	func _generate_preview(asset : Asset) -> Texture:
		return yield(PreviewRenderer.get_preview_for_brush(asset.data, Vector2(128, 128)), "completed")

class Asset:
	var name : String
	var type : AssetType
	var tags : Array
	var file : String
	var data

func _ready():
	if ProjectSettings.get_setting("application/config/load_assets"):
		for asset_type in ASSET_TYPES.values():
			load_assets(asset_type)
	_update_tag_list()
	_update_asset_list()


func get_drag_data_fw(position : Vector2, _from : Control):
	var item := asset_list.get_item_at_position(position, true)
	if item != -1:
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = asset_list.get_item_icon(item)
		set_drag_preview(preview)
		return asset_list.get_item_metadata(item)


func load_assets(asset_type : AssetType) -> void:
	var dir := Directory.new()
	var asset_dir := asset_type.get_asset_directory()
	dir.make_dir_recursive(asset_dir)
	dir.open(asset_dir)
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	while file_name != "":
		var asset := Asset.new()
		asset.name = file_name.get_basename()
		asset.type = asset_type
		asset.tags.append(asset_type.tag)
		asset.file = asset_dir.plus_file(file_name)
		asset.data = asset_type._load(asset)
		add_asset(asset)
		file_name = dir.get_next()


func add_asset(asset : Asset) -> void:
	for tag in asset.tags + ["all"]:
		if not tag in tagged_assets:
			tagged_assets[tag] = []
		tagged_assets[tag].append(asset)


func _on_AssetList_item_activated(index : int, item_list : ItemList) -> void:
	emit_signal("asset_activated", item_list.get_item_metadata(index))


func _update_tag_list() -> void:
	tag_list.clear()
	var root := tag_list.create_item()
	for tag in tags:
		var tag_item := tag_list.create_item(root)
		tag_item.set_text(0, tag)


func _update_asset_list() -> void:
	asset_list.clear()
	if not current_tag in tagged_assets:
		return
	for asset in tagged_assets[current_tag]:
		asset_list.add_item(asset.name, asset.type.get_preview(asset))
		asset_list.set_item_metadata(asset_list.get_item_count() - 1, asset)


func _on_RemoveTagButton_pressed() -> void:
	pass # Replace with function body.


func _on_AddTagButton_pressed() -> void:
	pass # Replace with function body.


func _on_TagList_cell_selected() -> void:
	current_tag = tag_list.get_selected().get_text(0)
	_update_asset_list()
