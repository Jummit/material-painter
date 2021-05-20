extends HBoxContainer

"""
A list of assets that can be drag-and dropped onto different UI elements

Each `AssetType` defines how to load the asset file and how to generate a
thumbnail for it.

Stored assets are sorted in folders by their type. They can be loaded from the
global asset library located in the user directory or from the asset library
local to the project.

Built-in effect assets are loaded from res://data/texture/json.

A list of tags can be modified by the user.
Assets are automatically tagged using their name and type. The user can
add and remove tags of assets. Tag metadata is stored in a json file in the
user directory.

Assets can be searched using the search bar.
"""

signal asset_activated(asset)

var _tag_list := ["all", "texture", "material", "brush", "effect"]
var _current_tag := "all"
var _progress_dialog
var _modifying_assets : Array
var _adding_tags : bool

const TextureAsset = preload("res://asset/texture_asset.gd")

onready var asset_store : Node = $"../../../../../../../AssetStore"
onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : ItemList = $VBoxContainer2/AssetList
onready var search_edit : LineEdit = $VBoxContainer2/SearchEdit
onready var tag_list : Tree = $VBoxContainer/TagList
onready var delete_asset_confirmation_dialog : ConfirmationDialog = $"../../../../../../../DeleteAssetConfirmationDialog"
onready var asset_popup_menu : PopupMenu = $"VBoxContainer2/AssetList/AssetPopupMenu"
onready var tag_modification_dialog : ConfirmationDialog = $"../../../../../../../TagModificationDialog"
onready var tag_edit : LineEdit = $"../../../../../../../TagModificationDialog/TagEdit"

func _ready():
	asset_list.set_drag_forwarding(self)
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")
	update_asset_list()
	_update_tag_list()


func update_asset_list() -> void:
	asset_list.clear()
	for asset in asset_store.search(search_edit.text + " " + _current_tag):
		var item := asset_list.get_item_count()
		asset_list.add_item(asset.name, asset.preview)
		asset_list.set_item_tooltip(item, "%s\n\n%s\nTags: %s" % [asset.name,
				asset.path, (asset.tags as PoolStringArray).join(", ")])
		asset_list.set_item_metadata(item, asset)


func _on_AssetList_item_activated(index : int) -> void:
	emit_signal("asset_activated", asset_list.get_item_metadata(index))


func _on_RemoveTagButton_pressed() -> void:
	if not tag_list.get_selected():
		return
	var tag := tag_list.get_selected().get_text(0)
	_current_tag = "all"
	_tag_list.erase(tag)
	update_asset_list()
	_update_tag_list()


func _on_AddTagButton_pressed() -> void:
	_add_tag()


func _on_TagList_cell_selected() -> void:
	_current_tag = tag_list.get_selected().get_text(0)
	update_asset_list()


func get_layout_data():
	return _tag_list


func _on_SearchEdit_text_changed(_new_text: String) -> void:
	update_asset_list()


func _on_DeleteAssetConfirmationDialog_confirmed():
	for item in delete_asset_confirmation_dialog.get_meta("items"):
		asset_store.remove_asset(item)


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
		if file.get_extension() == "png":
			var destination := "user://assets/texture".plus_file(
					file.get_base_dir())
			dir.copy(file, destination)
			asset_store.load_asset(destination, TextureAsset)
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
	for tag in _tag_list:
		var tag_item := tag_list.create_item(root)
		tag_item.set_text(0, tag)


func _add_tag() -> void:
	var new_tag := tag_name_edit.text.to_lower()
	if new_tag and not new_tag in _tag_list:
		_tag_list.append(new_tag)
		_current_tag = new_tag
		tag_name_edit.text = ""
		_update_tag_list()
		update_asset_list()


func _show_delete_confirmation_popup() -> void:
	var items := asset_list.get_selected_items()
	var names : PoolStringArray = []
	for item in items:
		names.append(asset_list.get_item_metadata(item).name)
	delete_asset_confirmation_dialog.dialog_text =\
			"Delete %s?" % names.join(", ")
	delete_asset_confirmation_dialog.popup()
	delete_asset_confirmation_dialog.set_meta("items", items)


func _modify_tags() -> void:
	var tag := tag_edit.text
	for asset in _modifying_assets:
		if _adding_tags:
			asset_store.add_asset_tag(asset, tag)
		else:
			asset_store.remove_asset_tag(asset, tag)
	update_asset_list()


func _on_layout_changed(meta) -> void:
	if meta is Dictionary and not meta.empty():
		_tag_list = meta
		update_asset_list()


func _on_Main_current_file_changed(_to) -> void:
	pass
