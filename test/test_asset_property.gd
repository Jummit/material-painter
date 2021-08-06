extends WATTest

var asset_property
var asset_store

const AssetStore = preload("res://asset/asset_store.gd")

#func start():
#

func test_loading():
	asset_store = AssetStore.new()
	asset_property = preload("res://asset/asset_property/asset_property.tscn").instance()
	asset_property.asset_store = asset_store
