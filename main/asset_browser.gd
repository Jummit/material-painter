extends HBoxContainer

"""
A list of assets that can be drag and dropped onto different UI elements

The tabs for each `AssetType` are generated procedurally.
Each `AssetType` defines how to load the asset file
and how to generate a thumbnail for it.
"""

signal asset_activated(asset)

var tagged_assets := {}
var tags := ["all", "texture", "material", "brush"]
var current_tag := "all"

var ASSET_TYPES := {
	TEXTURE = TextureAssetType.new(),
	MATERIAL = MaterialAssetType.new(),
	BRUSH = BrushAssetType.new(),
}

onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : ItemList = $VBoxContainer2/AssetList
onready var search_edit : LineEdit = $VBoxContainer2/SearchEdit
onready var tag_list : Tree = $VBoxContainer/TagList
onready var progress_dialog : PopupDialog = $"../../../../../../../ProgressDialog"

class AssetType:
	var name : String
	var tag : String
	
	func _init(_name : String, _tag : String) -> void:
		name = _name
		tag = _tag
	
	func get_preview(asset : Asset) -> Texture:
		var cached_thumbnail_path := get_cached_thumbnails_path().plus_file(asset.file.get_file().get_basename() + ".png")
		var dir := Directory.new()
		dir.make_dir_recursive(get_cached_thumbnails_path())
		var preview
		if dir.file_exists(cached_thumbnail_path):
			var preview_image := Image.new()
			preview_image.load(cached_thumbnail_path)
			preview = ImageTexture.new()
			preview.create_from_image(preview_image)
		else:
			preview = _generate_preview(asset)
			if preview is GDScriptFunctionState:
				preview = yield(preview, "completed")
			preview.get_data().save_png(cached_thumbnail_path)
		return preview
	
	func _generate_preview(_asset : Asset) -> Texture:
		return null
	
	func _load(asset : Asset):
		return load(asset.file)
	
	func get_asset_directory() -> String:
		return "user://".plus_file(name.to_lower())
	
	func get_local_asset_directory(project_file : String) -> String:
		return project_file.get_base_dir().plus_file("assets").plus_file(name.to_lower())
	
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
	const MaterialLayer = preload("res://resources/material/material_layer.gd")
	const LayerTexture = preload("res://resources/texture/layer_texture.gd")
	const LayerMaterial = preload("res://resources/material/layer_material.gd")
	
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
	asset_list.set_drag_forwarding(self)
	
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")
	
	yield(progress_dialog, "ready")
	
	if ProjectSettings.get_setting("application/config/load_assets"):
		var total_files := 0
		for asset_type in ASSET_TYPES.values():
			total_files += _get_files_in_folder(asset_type.get_asset_directory()).size()
		
		progress_dialog.start_task("Load Assets", total_files)
		
		for asset_type in ASSET_TYPES.values():
			var result = load_assets(asset_type.get_asset_directory(), asset_type)
			if result is GDScriptFunctionState:
				yield(result, "completed")
		
		progress_dialog.complete_task()
	update_tag_list()
	update_asset_list()


func get_drag_data_fw(position : Vector2, _from : Control):
	var item := asset_list.get_item_at_position(position, true)
	if item != -1:
		var preview := TextureRect.new()
		preview.rect_size = Vector2(64, 64)
		preview.expand = true
		preview.texture = asset_list.get_item_icon(item)
		set_drag_preview(preview)
		return asset_list.get_item_metadata(item)


func load_local_assets(project_file : String) -> void:
	if ProjectSettings.get_setting("application/config/load_assets"):
		for asset_type in ASSET_TYPES.values():
			load_assets(asset_type.get_local_asset_directory(project_file), asset_type, "local")


func load_assets(directory : String, asset_type : AssetType, common_tag := "") -> void:
	var dir := Directory.new()
	dir.make_dir_recursive(directory)
	var files := _get_files_in_folder(directory)
	for file in files:
		progress_dialog.start_action(file)
		load_asset(directory.plus_file(file), asset_type, common_tag)
		yield(get_tree(), "idle_frame")


func load_asset(path : String, asset_type : AssetType, tag := "") -> void:
	var asset := Asset.new()
	asset.name = path.get_file().get_basename()
	asset.type = asset_type
	asset.tags.append(asset_type.tag)
	asset.tags += Array(_get_tags(asset.name))
	if not tag in tags:
		tags.append(tag)
	if tag:
		asset.tags.append(tag)
	asset.file = path
	asset.data = asset_type._load(asset)
	add_asset(asset)


func add_asset(asset : Asset) -> void:
	for tag in asset.tags + ["all"]:
		if not tag in tagged_assets:
			tagged_assets[tag] = []
		tagged_assets[tag].append(asset)


func update_asset_list() -> void:
	asset_list.clear()
	if not current_tag in tagged_assets:
		return
	for asset in tagged_assets[current_tag]:
		var searched_for := not search_edit.text
		for tag in asset.tags:
			if search_edit.text.to_lower() in tag:
				searched_for = true
				break
		if searched_for:
			asset_list.add_item(asset.name, asset.type.get_preview(asset))
			asset_list.set_item_metadata(asset_list.get_item_count() - 1, asset)


func update_tag_list() -> void:
	tag_list.clear()
	var root := tag_list.create_item()
	for tag in tags:
		var tag_item := tag_list.create_item(root)
		tag_item.set_text(0, tag)


func _on_AssetList_item_activated(index : int) -> void:
	emit_signal("asset_activated", asset_list.get_item_metadata(index))


func _on_RemoveTagButton_pressed() -> void:
	tags.erase(tag_list.get_selected().get_text(0))
	update_tag_list()


func _on_AddTagButton_pressed() -> void:
	var new_tag := tag_name_edit.text.to_lower()
	if new_tag and not new_tag in tags:
		tags.append(new_tag)
		current_tag = new_tag
		update_tag_list()


func _on_TagList_cell_selected() -> void:
	current_tag = tag_list.get_selected().get_text(0)
	update_asset_list()


func _on_SearchEdit_text_changed(_new_text: String) -> void:
	update_asset_list()


func _on_SceneTree_files_dropped(files : PoolStringArray, _screen : int) -> void:
	var dir := Directory.new()
	for file in files:
		var new_asset_path : String = ASSET_TYPES.TEXTURE.get_asset_directory().plus_file(file.get_file())
		if dir.file_exists(new_asset_path):
			return
		if file.get_extension() == "png":
			dir.copy(file, new_asset_path)
			load_asset(file, ASSET_TYPES.TEXTURE)
			update_asset_list()


func _get_tags(asset_name : String) -> PoolStringArray:
	for letter in asset_name:
		if int(letter):
			asset_name = asset_name.replace(letter, "")
		if letter.to_upper() == letter:
			asset_name = asset_name.replace(letter, "_" + letter)
	return asset_name.to_lower().split("_", false)


func _get_files_in_folder(folder : String) -> PoolStringArray:
	var dir := Directory.new()
	dir.open(folder)
	dir.list_dir_begin(true)
	var file_name := dir.get_next()
	var files : PoolStringArray = []
	while file_name != "":
		files.append(file_name)
		file_name = dir.get_next()
	return files
