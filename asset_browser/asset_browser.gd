extends HBoxContainer

"""
A list of assets that can be drag-and dropped onto different UI elements

Each `AssetType` defines how to load the asset file and how to generate a
thumbnail for it.

Stored assets are sorted in folders by their type. They can be loaded from the
global asset library located in the user directory or from the asset library
local to the project.

Built-in effect assets are loaded from res://resources/texture/json.

A list of tags can be modified by the user.
Assets are automatically tagged using their name and type. The user can
add and remove tags of assets. Tag metadata is stored in a json file in the
user directory.

Assets can be searched using the search bar.
"""

signal asset_activated(asset)
signal right_click_effect_loaded(effect)

var project : ProjectFile

var _assets := []
var _already_tagged_assets := []
var _tagged_assets := {}
var _tag_metadata := {}
var _sidebar_tags := ["all", "texture", "material", "brush", "effect"]
var _current_tag := "all"
var _progress_dialog

var ASSET_TYPES := {
	TEXTURE = AssetTypes.TextureAssetType.new(),
	MATERIAL = AssetTypes.MaterialAssetType.new(),
	BRUSH = AssetTypes.BrushAssetType.new(),
	EFFECT = AssetTypes.EffectAssetType.new(),
	HDR = AssetTypes.HDRAssetType.new(),
}

const EFFECTS := "res://resources/texture/json"
const HDRS := "res://misc/hdrs"
const TAG_METADATA := "user://tags.json"

const Asset = preload("res://asset_browser/asset_classes.gd").Asset
const AssetType = preload("res://asset_browser/asset_classes.gd").AssetType
const AssetTypes = preload("res://asset_browser/asset_classes.gd")
const ProjectFile = preload("res://resources/project_file.gd")

onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : ItemList = $VBoxContainer2/AssetList
onready var search_edit : LineEdit = $VBoxContainer2/SearchEdit
onready var tag_list : Tree = $VBoxContainer/TagList
onready var delete_asset_confirmation_dialog : ConfirmationDialog = $"../../../../../../../DeleteAssetConfirmationDialog"
onready var asset_popup_menu : PopupMenu = $"VBoxContainer2/AssetList/AssetPopupMenu"
onready var tag_modification_dialog : ConfirmationDialog = $"../../../../../../../TagModificationDialog"
onready var tag_edit : LineEdit = $"../../../../../../../TagModificationDialog/TagEdit"
onready var preview_renderer : Node = $PreviewRenderer

func _ready():
	asset_list.set_drag_forwarding(self)
	
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")
	
	_load_tag_metadata()
	
	_progress_dialog = ProgressDialogManager.create_task("Load Assets", ASSET_TYPES.size())
	
	for asset_type in ASSET_TYPES.values():
		var result = _load_assets(asset_type.get_directory(), asset_type)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		_assets += result
	_assets += yield(_load_assets(EFFECTS, ASSET_TYPES.EFFECT), "completed")
	_assets += yield(_load_assets(HDRS, ASSET_TYPES.HDR), "completed")
	
	_progress_dialog.complete_task()
	_save_tag_metadata()
	
	_update_tag_list()
	update_asset_list()


func load_asset(path : String, asset_type : AssetType) -> Asset:
	var asset := Asset.new()
	asset.name = path.get_file().get_basename()
	asset.type = asset_type
	asset.file = path
	asset.data = asset_type._load(asset)
	if asset_type == ASSET_TYPES.EFFECT and "in_context_menu" in asset.data.data\
			and asset.data.data.in_context_menu:
		emit_signal("right_click_effect_loaded", asset.data)
		return null
	if not path in _already_tagged_assets:
		_add_asset_to_tag(asset, asset_type.tag)
		for tag in _get_tags(asset.name):
			_add_asset_to_tag(asset, tag)
		_add_asset_to_tag(asset, "all")
		_already_tagged_assets.append(path)
	for tag in _tag_metadata:
		if asset.file in _tag_metadata[tag]:
			_add_asset_to_tag(asset, tag)
	var result = asset_type.get_preview(preview_renderer, asset)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	asset.preview = result
	return asset


func update_asset_list() -> void:
	asset_list.clear()
	var search_terms := search_edit.text.to_lower().replace(",", " ").split(
			" ", false)
	var found_assets := []
	if not _current_tag in _tagged_assets:
		return
	if search_terms.size():
		for _asset in _tagged_assets[_current_tag]:
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
		found_assets = _tagged_assets[_current_tag]
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


func _on_AssetList_item_activated(index : int) -> void:
	emit_signal("asset_activated", asset_list.get_item_metadata(index))


func _on_RemoveTagButton_pressed() -> void:
	if not tag_list.get_selected():
		return
	var tag := tag_list.get_selected().get_text(0)
	_current_tag = "all"
	_sidebar_tags.erase(tag)
	_save_tag_metadata()
	_update_tag_list()
	update_asset_list()


func _on_AddTagButton_pressed() -> void:
	_add_tag()


func _on_TagList_cell_selected() -> void:
	_current_tag = tag_list.get_selected().get_text(0)
	update_asset_list()


func get_layout_data() -> String:
	return _current_tag


func _on_SearchEdit_text_changed(_new_text: String) -> void:
	update_asset_list()


func _on_DeleteAssetConfirmationDialog_confirmed():
	for item in delete_asset_confirmation_dialog.get_meta("items"):
		_delete_asset(item)


func _on_AssetList_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("delete_asset") and\
			asset_list.is_anything_selected():
		_show_delete_confirmation_popup()


func _on_AssetPopupMenu_id_pressed(id : int) -> void:
	match id:
		0:
			tag_modification_dialog.window_title = "Add Tag"
			tag_modification_dialog.set_meta("action", "add")
		1:
			tag_modification_dialog.window_title = "Remove Tag"
			tag_modification_dialog.set_meta("action", "remove")
		2:
			_show_delete_confirmation_popup()
	if id < 2:
		tag_modification_dialog.set_meta("items",
				asset_popup_menu.get_meta("items"))
		tag_modification_dialog.popup()
		tag_edit.grab_focus()
		tag_edit.select_all()


func _on_AssetList_item_rmb_selected(_index : int, at_position : Vector2) -> void:
	asset_popup_menu.set_meta("items", asset_list.get_selected_items())
	asset_popup_menu.popup()
	asset_popup_menu.rect_position = asset_list.rect_global_position + at_position


func _on_TagEdit_text_entered(_new_text : String) -> void:
	tag_modification_dialog.hide()
	_modify_tags()


func _on_TagModificationDialog_confirmed():
	_modify_tags()


func _on_TagNameEdit_text_entered(_new_text : String) -> void:
	_add_tag()


func _on_SceneTree_files_dropped(files : PoolStringArray, _screen : int) -> void:
	_progress_dialog = ProgressDialogManager.create_task("Import Assets",
			files.size())
	var dir := Directory.new()
	for file in files:
		_progress_dialog.set_action(file)
		yield(get_tree(), "idle_frame")
		for asset_type in ASSET_TYPES.values():
			if file.get_extension() == asset_type.extension:
				dir.copy(file, asset_type.get_directory().plus_file(
						file.get_file()))
				load_asset(file, asset_type)
				update_asset_list()
	_progress_dialog.complete_task()


func get_drag_data_fw(position : Vector2, _from : Control):
	var item := asset_list.get_item_at_position(position, true)
	if item != -1:
		var preview := Control.new()
		var preview_texture := TextureRect.new()
		preview_texture.rect_size = Vector2(100, 100)
		preview_texture.expand = true
		preview_texture.texture = asset_list.get_item_icon(item)
		preview.add_child(preview_texture)
		preview_texture.rect_position = - preview_texture.rect_size / 2
		set_drag_preview(preview)
		return asset_list.get_item_metadata(item)


func _update_tag_list() -> void:
	tag_list.clear()
	var root := tag_list.create_item()
	for tag in _sidebar_tags:
		var tag_item := tag_list.create_item(root)
		tag_item.set_text(0, tag)


func _add_tag() -> void:
	var new_tag := tag_name_edit.text.to_lower()
	if new_tag and not new_tag in _sidebar_tags:
		_sidebar_tags.append(new_tag)
		_current_tag = new_tag
		tag_name_edit.text = ""
		_update_tag_list()
		update_asset_list()
		_save_tag_metadata()


func _add_asset_to_tag(asset : Asset, tag : String) -> void:
	if not tag in asset.tags:
		asset.tags.append(tag)
	if not tag in _tagged_assets:
		_tagged_assets[tag] = []
	if not asset in _tagged_assets[tag]:
		_tagged_assets[tag].append(asset)


func _load_local_assets(project_file : String) -> void:
	var total_files := 0
	for asset_type in ASSET_TYPES.values():
		total_files += _get_files_in_folder(
				asset_type.get_local_directory(project_file)).size()
	_progress_dialog = ProgressDialogManager.create_task("Load Local Assets",
		total_files)
	for asset_type in ASSET_TYPES.values():
		var result = _load_assets(asset_type.get_local_directory(
				project_file), asset_type)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		_assets += result
		for asset in result:
			_add_asset_to_tag(asset, "local")
	_progress_dialog.complete_task()
	_save_tag_metadata()


func _load_assets(directory : String, asset_type : AssetType) -> Array:
	var new_assets := []
	var dir := Directory.new()
	dir.make_dir_recursive(directory)
	var files := _get_files_in_folder(directory)
	_progress_dialog.set_action(asset_type.name)
	yield(get_tree(), "idle_frame")
	for file_num in files.size():
		var file := files[file_num]
		if file.get_extension() != asset_type.extension:
			continue
		var asset = load_asset(directory.plus_file(file), asset_type)
		if asset is GDScriptFunctionState:
			asset = yield(asset, "completed")
		if asset:
			new_assets.append(asset)
	return new_assets


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


func _show_delete_confirmation_popup() -> void:
	var items := asset_list.get_selected_items()
	var names : PoolStringArray = []
	for item in items:
		names.append(asset_list.get_item_metadata(item).name)
	delete_asset_confirmation_dialog.dialog_text =\
			"Delete %s?" % names.join(", ")
	delete_asset_confirmation_dialog.popup()
	delete_asset_confirmation_dialog.set_meta("items", items)


func _delete_asset(item : int) -> void:
	var asset : Asset = asset_list.get_item_metadata(item)
	
	for tag in _tagged_assets:
		_remove_asset_from_tag(asset, tag)
	
	var dir := Directory.new()
	dir.remove(project.get_global_path(asset.file))
	dir.remove(asset.get_cached_thumbnail_path())
	
	asset_list.remove_item(item)


func _remove_asset_from_tag(asset : Asset, tag : String) -> void:
	asset.tags.erase(tag)
	if asset in _tagged_assets[tag]:
		_tagged_assets[tag].erase(asset)
	if not _tagged_assets[tag].size() and not tag in _sidebar_tags:
		_tagged_assets.erase(tag)


func _modify_tags() -> void:
	var tag := tag_edit.text
	var items : PoolIntArray = tag_modification_dialog.get_meta("items")
	for item in items:
		var asset : Asset = asset_list.get_item_metadata(item)
		if tag_modification_dialog.get_meta("action") == "add":
			_add_asset_to_tag(asset, tag)
		else:
			_remove_asset_from_tag(asset, tag)
	update_asset_list()


func _save_tag_metadata() -> void:
	var data := {
		sidebar = _sidebar_tags,
		assets = {},
		tagged = _already_tagged_assets,
	}
	for tag in _tagged_assets:
		data.assets[tag] = []
		for asset in _tagged_assets[tag]:
			data.assets[tag].append(asset.file)
	var file := File.new()
	file.open(TAG_METADATA, File.WRITE)
	file.store_string(to_json(data))
	file.close()


func _load_tag_metadata() -> void:
	var file := File.new()
	if file.open(TAG_METADATA, File.READ) == OK:
		var data : Dictionary = parse_json(file.get_as_text())
		_sidebar_tags = data.sidebar
		_tag_metadata = data.assets
		_already_tagged_assets = data.tagged
	file.close()


func _on_layout_changed(meta) -> void:
	if meta:
		_current_tag = meta
		update_asset_list()


func _on_Main_current_file_changed(to : ProjectFile) -> void:
	project = to
	if project.resource_path:
		_load_local_assets(project.resource_path)
