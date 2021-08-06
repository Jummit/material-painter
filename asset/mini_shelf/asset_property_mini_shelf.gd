extends "res://asset/mini_shelf/mini_shelf.gd"

var current_property : AssetProperty

const AssetProperty = preload("res://asset/asset_property/asset_property.gd")

func _ready() -> void:
	set_asset_store(get_node("../AssetStore"))
	get_tree().connect("node_added", self, "_on_SceneTree_node_added")


func _on_SceneTree_node_added(node : Node) -> void:
	if node is AssetProperty and not node.is_connected("minishelf_opened", self,
				"_on_AssetProperty_minishelf_opened"):
		node.connect("minishelf_opened", self,
				"_on_AssetProperty_minishelf_opened", [node])


func _on_AssetProperty_minishelf_opened(property : AssetProperty) -> void:
	asset_list.filter = ""
	for type in property.allowed_assets:
		asset_list.filter += type.get_type() + " "
	current_property = property
	popup(Rect2(property.rect_global_position, rect_size))


func _on_asset_selected(asset) -> void:
	current_property.value = asset
	hide()
