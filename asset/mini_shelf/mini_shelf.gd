extends Popup

signal asset_selected(asset)

var asset_store : AssetStore setget set_asset_store
var allowed_assets : Array setget set_allowed_assets

const AssetStore = preload("res://asset/asset_store.gd")
const AssetList = preload("res://asset/asset_list/asset_list.gd")
const Asset = preload("res://asset/assets/asset.gd")

onready var asset_list : AssetList = $Panel/AssetList

func set_asset_store(to : AssetStore) -> void:
	asset_store = to
	asset_list.asset_store = asset_store


func set_allowed_assets(to : Array) -> void:
	allowed_assets = to
	asset_list.filter = ""
	for asset in allowed_assets:
		asset_list.filter += asset.get_type() + " "


func _on_AssetList_asset_selected(asset : Asset) -> void:
	emit_signal("asset_selected", asset)


func _on_about_to_show() -> void:
	asset_list.focus_search()
