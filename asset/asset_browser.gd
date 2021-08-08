extends HBoxContainer

"""
A panel used used to browse, add, delete and modify assets

Stored assets are sorted in folders by their type. They can be loaded from the
global asset library located in the user directory, or from the asset library
local to the project.

Built-in assets are loaded from res://assets.

The tags assigned to an assets can be modified by the user. Assets are
automatically tagged using their name and type. The user can add and remove
tags of assets. Tag metadata is stored in a json file in the user directory.
"""

var _tag_list := ["all", "texture", "material", "brush", "effect"]
var _progress_dialog
var _modifying_assets : Array
var _adding_tags : bool

const TextureAsset = preload("assets/texture_asset.gd")
const EffectAsset = preload("assets/effect_asset.gd")
const AssetStore = preload("asset_store.gd")
const AssetList = preload("asset_list/asset_list.gd")

onready var asset_store : AssetStore = $"../../../../../../../AssetStore"
onready var tag_name_edit : LineEdit = $VBoxContainer/HBoxContainer/TagNameEdit
onready var asset_list : AssetList = $AssetList
onready var tag_list : Tree = $VBoxContainer/TagList
onready var delete_asset_confirmation_dialog : ConfirmationDialog = $"../../../../../../../DeleteAssetConfirmationDialog"
onready var asset_popup_menu : PopupMenu = $AssetList/AssetPopupMenu
onready var tag_modification_dialog : ConfirmationDialog = $"../../../../../../../TagModificationDialog"
onready var tag_edit : LineEdit = $"../../../../../../../TagModificationDialog/TagEdit"

func _ready():
	get_tree().connect("files_dropped", self, "_on_SceneTree_files_dropped")
	asset_list.update_list()
	asset_list.asset_store = asset_store
	_update_tag_list()


# Tag editing

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
		asset_list.filter = new_tag
		tag_name_edit.text = ""
		_update_tag_list()


func _modify_tags() -> void:
	var tag := tag_edit.text
	for asset in _modifying_assets:
		if _adding_tags:
			asset_store.add_asset_tag(asset, tag)
		else:
			asset_store.remove_asset_tag(asset, tag)
	asset_list.update_list()


# Signal callbacks

func _on_RemoveTagButton_pressed() -> void:
	if not tag_list.get_selected():
		return
	var tag := tag_list.get_selected().get_text(0)
	asset_list.filter = "all"
	_tag_list.erase(tag)
	asset_list.update_list()
	_update_tag_list()


func _on_AddTagButton_pressed() -> void:
	_add_tag()


func _on_TagList_cell_selected() -> void:
	asset_list.filter = tag_list.get_selected().get_text(0)


func _on_DeleteAssetConfirmationDialog_confirmed():
	for asset in delete_asset_confirmation_dialog.get_meta("assets"):
		asset_store.remove_asset(asset)


func _on_AssetList_gui_input(event : InputEvent) -> void:
	if event.is_action_pressed("delete_asset") and\
			asset_list.get_selected_assets().size():
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
		tag_modification_dialog.set_meta("assets",
				asset_popup_menu.get_meta("assets"))
		tag_modification_dialog.popup()
		tag_edit.grab_focus()
		tag_edit.select_all()


func _on_AssetList_item_rmb_selected(_index : int,
		at_position : Vector2) -> void:
	asset_popup_menu.set_meta("assets", asset_list.get_selected_assets())
	asset_popup_menu.popup()
	asset_popup_menu.rect_position = asset_list.rect_global_position + at_position


func _on_TagEdit_text_entered(_new_text : String) -> void:
	tag_modification_dialog.hide()
	_modify_tags()


func _on_TagModificationDialog_confirmed():
	_modify_tags()


func _on_TagNameEdit_text_entered(_new_text : String) -> void:
	_add_tag()


func _on_SceneTree_files_dropped(files : PoolStringArray,
		_screen : int) -> void:
# warning-ignore:unsafe_method_access
	_progress_dialog = ProgressDialogManager.create_task("Import Assets",
			files.size())
	var dir := Directory.new()
	for file in files:
		_progress_dialog.set_action(file)
		yield(get_tree(), "idle_frame")
		if file.get_extension() == "png":
			dir.make_dir_recursive("user://assets/texture")
			var destination := "user://assets/texture".plus_file(
					file.get_file())
			dir.copy(file, destination)
			asset_store.load_asset(destination, TextureAsset)
			asset_list.update_list()
	_progress_dialog.complete_task()


func _on_layout_changed(meta) -> void:
	if meta is Dictionary and not meta.empty():
		_tag_list = meta
		asset_list.update_list()


# Misc

func _show_delete_confirmation_popup() -> void:
	var assets := asset_list.get_selected_assets()
	var names : PoolStringArray = []
	for asset in assets:
		names.append(asset)
	delete_asset_confirmation_dialog.dialog_text =\
			"Delete %s?" % names.join(", ")
	delete_asset_confirmation_dialog.popup()
	delete_asset_confirmation_dialog.set_meta("assets", assets)


func get_layout_data():
	return _tag_list
