extends VBoxContainer

signal asset_selected(asset)

export var thumbnail_size := 128

var filter : String setget set_filter
var asset_store : AssetStore setget set_asset_store

const AssetStore = preload("res://asset/asset_store.gd")
const Asset = preload("res://asset/assets/asset.gd")

onready var item_list : ItemList = $ItemList
onready var search_edit : LineEdit = $SearchEdit

func _ready() -> void:
	item_list.set_drag_forwarding(self)


func get_drag_data_fw(position : Vector2, _from : Control):
	var item := item_list.get_item_at_position(position, true)
	if item != -1:
		var preview := Control.new()
		var preview_texture := TextureRect.new()
		preview_texture.rect_size = Vector2(100, 100)
		preview_texture.expand = true
		preview_texture.texture = item_list.get_item_icon(item)
		preview.add_child(preview_texture)
		preview_texture.rect_position = - preview_texture.rect_size / 2
		set_drag_preview(preview)
		return item_list.get_item_metadata(item)


func focus_search() -> void:
	search_edit.grab_focus()


func set_asset_store(to) -> void:
	asset_store = to
	asset_store.connect("asset_loaded", self, "_on_AssetStore_asset_loaded")
	asset_store.connect("asset_unloaded", self, "_on_AssetStore_asset_unloaded")
	update_list()


func set_filter(to : String) -> void:
	filter = to
	update_list()


func update_list() -> void:
	if not asset_store:
		return
	item_list.clear()
	for asset in asset_store.search(filter + " " + search_edit.text):
		var item := item_list.get_item_count()
		var thumbnail : Texture = asset_store.thumbnails[asset.path]
		if thumbnail.get_size().x != thumbnail_size:
			var image := thumbnail.get_data()
			image.resize(thumbnail_size, thumbnail_size)
			var new := ImageTexture.new()
			new.create_from_image(image)
			thumbnail = new
		item_list.add_item(asset.name, thumbnail)
# warning-ignore:unsafe_cast
		item_list.set_item_tooltip(item, "%s\n\n%s\nTags: %s" % [asset.name,
				asset.path, (asset_store.asset_tags[asset.path]\
				as PoolStringArray).join(", ")])
		item_list.set_item_metadata(item, asset)
	if item_list.get_item_count():
		item_list.select(0)


func _on_AssetStore_asset_loaded(_asset) -> void:
	update_list()


func _on_AssetStore_asset_unloaded(_asset) -> void:
	update_list()


func get_selected_assets() -> Array:
	var assets = []
	for item in item_list.get_selected_items():
		assets.append(item_list.get_item_metadata(item))
	return assets


func _on_SearchEdit_text_changed(_new_text : String) -> void:
	update()


func _on_SearchEdit_text_entered(_new_text : String) -> void:
	emit_signal("asset_selected", get_selected_assets().front())


func _on_ItemList_item_activated(index: int) -> void:
	emit_signal("asset_selected", item_list.get_item_metadata(index))
