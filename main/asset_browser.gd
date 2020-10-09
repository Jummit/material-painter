extends TabContainer

"""
A list of assets that can be drag and dropped onto different UI elements

The tabs for each `AssetType` are generated procedurally.
Each `AssetType` defines how to load the asset file
and how to generate a thumbnail for it.
"""

signal asset_activated(asset)

var asset_type_item_lists : Dictionary

var ASSET_TYPES := {
	TEXTURE = TextureAssetType.new(),
	MATERIAL = MaterialAssetType.new(),
	BRUSH = BrushAssetType.new(),
}

class AssetType:
	var name : String
	var directory : String
	
	func _init(_name : String, _directory : String) -> void:
		name = _name
		directory = _directory
	
	func _generate_preview(_asset : Resource) -> Texture:
		return null
	
	func _load(path : String):
		return load(path)
	
	func get_asset_directory() -> String:
		return "user://".plus_file(directory)
	
	func get_cashed_thumbnails_path() -> String:
		return "user://cashed_thumbnails/" + directory

class TextureAssetType extends AssetType:
	func _init().("Textures", "textures") -> void:
		pass
	
	func _generate_preview(asset) -> Texture:
		var image := Image.new()
		image.load(asset)
		image.resize(128, 128)
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image)
		return image_texture
	
	func _load(path : String):
		return path

class MaterialAssetType extends AssetType:
	const MaterialLayer = preload("res://resources/material_layer.gd")
	const LayerTexture = preload("res://resources/layer_texture.gd")
	const LayerMaterial = preload("res://resources/layer_material.gd")
	
	func _init().("Materials", "materials") -> void:
		pass
	
	func _generate_preview(asset : Resource) -> Texture:
		var material_to_render := LayerMaterial.new()
		material_to_render.layers.append(asset)
		return yield(PreviewRenderer.get_preview_for_material(material_to_render, Vector2(128, 128)), "completed")

class BrushAssetType extends AssetType:
	func _init().("Brushes", "brushes") -> void:
		pass
	
	func _generate_preview(asset : Resource) -> Texture:
		return yield(PreviewRenderer.get_preview_for_brush(asset, Vector2(128, 128)), "completed")

func _ready():
	if ProjectSettings.get_setting("application/config/load_assets"):
		for asset_type in ASSET_TYPES.values():
			load_assets(asset_type)
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")


func load_assets(asset_type : AssetType) -> void:
	var item_list := ItemList.new()
	item_list.name = asset_type.name
	item_list.set_meta("type", asset_type)
	asset_type_item_lists[asset_type] = item_list
	item_list.icon_mode = ItemList.ICON_MODE_TOP
	item_list.same_column_width = true
	item_list.max_columns = 100
	item_list.fixed_icon_size = Vector2(128, 128)
	item_list.set_drag_forwarding(self)
	item_list.connect("item_activated", self, "_on_AssetList_item_activated", [item_list])
	add_child(item_list)
	
	var dir := Directory.new()
	dir.make_dir_recursive(asset_type.get_asset_directory())
	dir.open(asset_type.get_asset_directory())
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	while file_name != "":
		var result = register_asset(file_name, asset_type)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		file_name = dir.get_next()


func get_drag_data_fw(position : Vector2, _from : Control):
	var item_list : ItemList = get_child(current_tab)
	var item := item_list.get_item_at_position(position, true)
	if item != -1:
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = item_list.get_item_icon(item)
		set_drag_preview(preview)
		return item_list.get_item_metadata(item)


func register_asset(file : String, asset_type : AssetType) -> void:
	var item_list : ItemList = asset_type_item_lists[asset_type]
	var asset = asset_type._load(asset_type.get_asset_directory().plus_file(file))
	var id := item_list.get_item_count()
	var cache_thumbnail_path := asset_type.get_cashed_thumbnails_path().plus_file(file.get_basename() + ".png")
	var dir := Directory.new()
	dir.make_dir_recursive(asset_type.get_cashed_thumbnails_path())
	var preview
	if dir.file_exists(cache_thumbnail_path):
		var preview_image := Image.new()
		preview_image.load(cache_thumbnail_path)
		preview = ImageTexture.new()
		preview.create_from_image(preview_image)
	else:
		preview = asset_type._generate_preview(asset)
		if preview is GDScriptFunctionState:
			preview = yield(preview, "completed")
		(preview as Texture).get_data().save_png(cache_thumbnail_path)
	item_list.add_item(file.get_file().get_basename(), preview)
	item_list.set_item_metadata(id, {type = asset_type.name, asset = asset})


func _on_AssetList_item_activated(index : int, item_list : ItemList) -> void:
	emit_signal("asset_activated", item_list.get_item_metadata(index))


func _on_SceneTree_files_dropped(files : PoolStringArray, _screen : int) -> void:
	var current_asset_type : AssetType = get_current_tab_control().get_meta("type")
	var dir := Directory.new()
	for file in files:
		dir.copy(file, current_asset_type.get_asset_directory().plus_file(file.get_file()))
		register_asset(file.get_file(), current_asset_type)
