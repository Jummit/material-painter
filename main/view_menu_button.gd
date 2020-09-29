extends MenuButton

"""
A menu containing view related options

Used to switch backgrounds.
HDRIs used are from `https://hdrihaven.com/`.
"""

var show_background := false

var hdris := {
	"Rocky Sea": "res://3d_viewport/hdrs/cannon_2k.hdr",
	"Modern House": "res://3d_viewport/hdrs/cayley_interior_2k.hdr",
	"Autuum Forest": "res://3d_viewport/hdrs/forest_cave_2k.hdr",
	"Forest River": "res://3d_viewport/hdrs/lauter_waterfall_2k.hdr",
}

var background_submenu_popup := PopupMenu.new()

enum Item {
	SHOW_BACKGROUND,
	CHANGE_BACKGROUND,
	VIEW_RESULTS,
}

signal hdri_selected(hdri)
signal show_background_toggled

onready var results_item_list : ItemList = $"../../../PanelContainer/HBoxContainer/ResultsItemList"

func _ready() -> void:
	get_popup().add_check_item("Show Background", Item.SHOW_BACKGROUND)
	background_submenu_popup.name = "Background"
	get_popup().add_child(background_submenu_popup)
	get_popup().add_submenu_item("Change Background", "Background", Item.CHANGE_BACKGROUND)
	get_popup().connect("id_pressed", self, "_on_Popup_id_pressed")
	background_submenu_popup.connect("index_pressed", self, "_on_Background_index_pressed")
	for hdri in hdris:
		background_submenu_popup.add_item(hdri)
	get_popup().add_check_item("View results", Item.VIEW_RESULTS)


func _on_Popup_id_pressed(id : int) -> void:
	match id:
		Item.SHOW_BACKGROUND:
			show_background = not show_background
			get_popup().set_item_checked(get_popup().get_item_index(Item.SHOW_BACKGROUND), show_background)
			emit_signal("show_background_toggled")
		Item.VIEW_RESULTS:
			results_item_list.visible = not results_item_list.visible
			get_popup().set_item_checked(get_popup().get_item_index(Item.VIEW_RESULTS), results_item_list.visible)


func _on_Background_index_pressed(index : int) -> void:
	emit_signal("hdri_selected", load(hdris[background_submenu_popup.get_item_text(index)]))
