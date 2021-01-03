extends HBoxContainer

"""
A list of assets that can be drag and dropped onto different UI elements

The tabs for each `AssetType` are generated procedurally.
Each `AssetType` defines how to load the asset file
and how to generate a thumbnail for it.
"""

signal asset_activated(asset)

var assets := []
var already_tagged_assets := []
var tagged_assets := {}
var tag_metadata := {}
var sidebar_tags := ["all", "texture", "material", "brush"]
var current_tag := "all"
var progress_dialog

var ASSET_TYPES := {
	TEXTURE = TextureAssetType.new(),
	MATERIAL = MaterialAssetType.new(),
	BRUSH = BrushAssetType.new(),
	EFFECT = EffectAssetType.new(),
}

onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : ItemList = $VBoxContainer2/AssetList
onready var search_edit : LineEdit = $VBoxContainer2/SearchEdit
onready var tag_list : Tree = $VBoxContainer/TagList
onready var delete_asset_confirmation_dialog : ConfirmationDialog = $"../../../../../../../DeleteAssetConfirmationDialog"
onready var asset_popup_menu : PopupMenu = $"VBoxContainer2/AssetList/AssetPopupMenu"
onready var tag_modification_dialog : ConfirmationDialog = $"../../../../../../../TagModificationDialog"
onready var tag_edit : LineEdit = $"../../../../../../../TagModificationDialog/TagEdit"

const JsonTextureLayer = preload("res://resources/texture/json_texture_layer.gd")

class AssetType:
	var name : String
	var tag : String
	var extension : String
	
	func _init(_name : String, _tag : String, _extension : String) -> void:
		name = _name
		tag = _tag
		extension = _extension
	
	func get_preview(asset : Asset) -> Texture:
		var cached_thumbnail_path := asset.get_cached_thumbnail_path()
		var custom_thumbnail_path := asset.get_custom_thumbnail_path()
		var dir := Directory.new()
		dir.make_dir_recursive(get_cached_thumbnails_path())
		var preview
		if dir.file_exists(custom_thumbnail_path):
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
			preview = _generate_preview(asset)
			if preview is GDScriptFunctionState:
				preview = yield(preview, "completed")
			if preview and preview.get_data():
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
	func _init().("Textures", "texture", "png") -> void:
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
	
	func _init().("Materials", "material", "tres") -> void:
		pass
	
	func _generate_preview(asset : Asset) -> Texture:
		var material_to_render := LayerMaterial.new()
		material_to_render.layers.append(asset.data)
		return yield(PreviewRenderer.get_preview_for_material(material_to_render, Vector2(128, 128)), "completed")

class BrushAssetType extends AssetType:
	func _init().("Brushes", "brush", "tres") -> void:
		pass
	
	func _generate_preview(asset : Asset) -> Texture:
		return yield(PreviewRenderer.get_preview_for_brush(asset.data, Vector2(128, 128)), "completed")

class EffectAssetType extends AssetType:
	func _init().("Effects", "effect", "json") -> void:
		pass
	
	func _load(asset : Asset):
		var layer := JsonTextureLayer.new(asset.file)
		return layer
	
	func _generate_preview(_asset : Asset) -> Texture:
		return preload("res://icon.svg")

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

func _ready():
	asset_list.set_drag_forwarding(self)
	
	Globals.connect("current_file_changed", self,
			"_on_Globals_current_file_changed")
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")
	
	if ProjectSettings.get_setting("application/config/load_assets"):
		load_tag_metadata()
		
		var total_files := 0
		for asset_type in ASSET_TYPES.values():
			total_files += _get_files_in_folder(
					asset_type.get_asset_directory()).size()
		
		progress_dialog = ProgressDialogManager.create_task("Load Assets",
				total_files)
		
		for asset_type in ASSET_TYPES.values():
			var result = load_assets(asset_type.get_asset_directory(),
					asset_type)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
			assets += result
		
		assets += yield(load_assets("res://resources/texture/json/",
				ASSET_TYPES.EFFECT), "completed")
		
		save_tag_metadata()
		
		progress_dialog.complete_task()
	
	update_tag_list()
	update_asset_list()


func _on_Globals_current_file_changed():
	if Globals.current_file.resource_path:
		load_local_assets(Globals.current_file.resource_path)


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
		var total_files := 0
		for asset_type in ASSET_TYPES.values():
			total_files += _get_files_in_folder(
					asset_type.get_local_asset_directory(project_file)).size()
		progress_dialog = ProgressDialogManager.create_task("Load Local Assets",
			total_files)
		for asset_type in ASSET_TYPES.values():
			var result = load_assets(
				asset_type.get_local_asset_directory(project_file), asset_type)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
			assets += result
			for asset in result:
				add_asset_to_tag(asset, "local")
		progress_dialog.complete_task()
		save_tag_metadata()


func load_assets(directory : String, asset_type : AssetType) -> Array:
	var new_assets := []
	var dir := Directory.new()
	dir.make_dir_recursive(directory)
	var files := _get_files_in_folder(directory)
	for file in files:
		if file.get_extension() != asset_type.extension:
			continue
		progress_dialog.set_action(file)
		var asset = load_asset(directory.plus_file(file), asset_type)
		if asset is GDScriptFunctionState:
			asset = yield(asset, "completed")
		new_assets.append(asset)
		yield(get_tree(), "idle_frame")
	return new_assets


func load_asset(path : String, asset_type : AssetType) -> Asset:
	var asset := Asset.new()
	asset.name = path.get_file().get_basename()
	asset.type = asset_type
	asset.file = path
	asset.data = asset_type._load(asset)
	if not path in already_tagged_assets:
		add_asset_to_tag(asset, asset_type.tag)
		for tag in _get_tags(asset.name):
			add_asset_to_tag(asset, tag)
		add_asset_to_tag(asset, "all")
		already_tagged_assets.append(path)
	for tag in tag_metadata:
		if asset.file in tag_metadata[tag]:
			add_asset_to_tag(asset, tag)
	var result  = asset_type.get_preview(asset)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	asset.preview = result
	return asset


func add_asset_to_tag(asset : Asset, tag : String) -> void:
	if not tag in asset.tags:
		asset.tags.append(tag)
	if not tag in tagged_assets:
		tagged_assets[tag] = []
	tagged_assets[tag].append(asset)


func update_asset_list() -> void:
	asset_list.clear()
	var search_terms := search_edit.text.to_lower().replace(",", " ").split(" ", false)
	var found_assets := []
	if not current_tag in tagged_assets:
		return
	if search_terms.size():
		for _asset in tagged_assets[current_tag]:
			var asset := _asset as Asset
			var matches := true
			var all_tags := (asset.tags as PoolStringArray).join(" ")
			for term in search_terms:
				if not term in all_tags:
					matches = false
					break
			if matches:
				found_assets.append(asset)
	else:
		found_assets = tagged_assets[current_tag]
	var added_assets := {}
	for asset in found_assets:
		if asset in added_assets:
			continue
		added_assets[asset] = true  
		var item := asset_list.get_item_count()
		asset_list.add_item(asset.name, asset.preview)
		asset_list.set_item_tooltip(item, "%s\n\n%s\nTags: %s" % [
				asset.name, asset.file,
				(asset.tags as PoolStringArray).join(", ")])
		asset_list.set_item_metadata(item, asset)


func update_tag_list() -> void:
	tag_list.clear()
	var root := tag_list.create_item()
	for tag in sidebar_tags:
		var tag_item := tag_list.create_item(root)
		tag_item.set_text(0, tag)


func _on_AssetList_item_activated(index : int) -> void:
	emit_signal("asset_activated", asset_list.get_item_metadata(index))


func _on_RemoveTagButton_pressed() -> void:
	if not tag_list.get_selected():
		return
	var tag := tag_list.get_selected().get_text(0)
	current_tag = "all"
	sidebar_tags.erase(tag)
	save_tag_metadata()
	update_tag_list()
	update_asset_list()


func _on_AddTagButton_pressed() -> void:
	add_tag()


func add_tag():
	var new_tag := tag_name_edit.text.to_lower()
	if new_tag and not new_tag in sidebar_tags:
		sidebar_tags.append(new_tag)
		current_tag = new_tag
		tag_name_edit.text = ""
		update_tag_list()
		update_asset_list()
		save_tag_metadata()


func _on_TagList_cell_selected() -> void:
	current_tag = tag_list.get_selected().get_text(0)
	update_asset_list()


func _on_SearchEdit_text_changed(_new_text: String) -> void:
	update_asset_list()


func _on_SceneTree_files_dropped(files : PoolStringArray, _screen : int) -> void:
	progress_dialog = ProgressDialogManager.create_task("Import Assets", files.size())
	var dir := Directory.new()
	for file in files:
		progress_dialog.set_action(file)
		yield(get_tree(), "idle_frame")
		var new_asset_path : String = ASSET_TYPES.TEXTURE.get_asset_directory().plus_file(file.get_file())
		if dir.file_exists(new_asset_path):
			continue
		var type : AssetType
		if file.get_extension() == "png":
			type = ASSET_TYPES.TEXTURE
		elif file.get_extension() == "json":
			type = ASSET_TYPES.EFFECT
		if type:
			dir.copy(file, new_asset_path)
			load_asset(file, type)
			update_asset_list()
	progress_dialog.complete_task()


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


func _on_DeleteAssetConfirmationDialog_confirmed():
	for item in delete_asset_confirmation_dialog.get_meta("items"):
		delete_asset(item)


func _on_AssetList_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("delete_asset") and\
			asset_list.is_anything_selected():
		show_delete_confirmation_popup()


func show_delete_confirmation_popup() -> void:
	var items := asset_list.get_selected_items()
	var names : PoolStringArray = []
	for item in items:
		names.append(asset_list.get_item_metadata(item).name)
	delete_asset_confirmation_dialog.dialog_text =\
			"Delete %s?" % names.join(", ")
	delete_asset_confirmation_dialog.popup()
	delete_asset_confirmation_dialog.set_meta("items", items)


func delete_asset(item : int) -> void:
	var asset : Asset = asset_list.get_item_metadata(item)
	
	for tag in tagged_assets:
		remove_asset_from_tag(asset, tag)
	
	var dir := Directory.new()
	dir.remove(Globals.get_global_asset_path(asset.file))
	dir.remove(asset.get_cached_thumbnail_path())
	
	asset_list.remove_item(item)


func remove_asset_from_tag(asset : Asset, tag : String) -> void:
	asset.tags.erase(tag)
	if asset in tagged_assets[tag]:
		tagged_assets[tag].erase(asset)
	if not tagged_assets[tag].size() and not tag in sidebar_tags:
		tagged_assets.erase(tag)


func _on_AssetPopupMenu_id_pressed(id : int) -> void:
	match id:
		0:
			tag_modification_dialog.window_title = "Add Tag"
			tag_modification_dialog.set_meta("action", "add")
		1:
			tag_modification_dialog.window_title = "Remove Tag"
			tag_modification_dialog.set_meta("action", "remove")
		2:
			show_delete_confirmation_popup()
	if id < 2:
#		tag_edit.text = ""
		tag_modification_dialog.set_meta("items", asset_popup_menu.get_meta("items"))
		tag_modification_dialog.popup()
		tag_edit.grab_focus()
		tag_edit.select_all()


func _on_AssetList_item_rmb_selected(_index : int, at_position : Vector2) -> void:
	asset_popup_menu.set_meta("items", asset_list.get_selected_items())
	asset_popup_menu.popup()
	asset_popup_menu.rect_position = asset_list.rect_global_position + at_position


func _on_TagEdit_text_entered(_new_text : String) -> void:
	tag_modification_dialog.hide()
	modify_tags()


func _on_TagModificationDialog_confirmed():
	modify_tags()


func modify_tags() -> void:
	var tag := tag_edit.text
	var items : PoolIntArray = tag_modification_dialog.get_meta("items")
	for item in items:
		var asset : Asset = asset_list.get_item_metadata(item)
		match tag_modification_dialog.get_meta("action"):
			"add":
				if tag in asset.tags:
					continue
				asset.tags.append(tag)
				add_asset_to_tag(asset, tag)
			"remove":
				remove_asset_from_tag(asset, tag)
	update_asset_list()


func save_tag_metadata() -> void:
	var data := {
		tagged = already_tagged_assets,
		assets = {},
		sidebar = sidebar_tags,
	}
	for tag in tagged_assets:
		data.assets[tag] = []
		for asset in tagged_assets[tag]:
			data.assets[tag].append(asset.file)
	var file := File.new()
	file.open("user://tags.json", File.WRITE)
	file.store_string(to_json(data))
	file.close()


func load_tag_metadata() -> void:
	var file := File.new()
	if file.open("user://tags.json", File.READ) == OK:
		var data : Dictionary = parse_json(file.get_as_text())
		sidebar_tags = data.sidebar
		tag_metadata = data.assets
		already_tagged_assets = data.tagged
	file.close()


func _on_TagNameEdit_text_entered(_new_text : String) -> void:
	add_tag()
