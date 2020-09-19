extends MenuButton

var show_background := false

var hdrs := {
	"Rocky Sea": "res://3d_viewport/hdrs/cannon_2k.hdr",
	"Modern House": "res://3d_viewport/hdrs/cayley_interior_2k.hdr",
	"Autuum Forest": "res://3d_viewport/hdrs/forest_cave_2k.hdr",
	"Forest River": "res://3d_viewport/hdrs/lauter_waterfall_2k.hdr",
}

var background_submenu_popup := PopupMenu.new()

signal hdr_selected(hdr)
signal show_background_toggled

func _ready() -> void:
	background_submenu_popup.name = "Background"
	get_popup().add_child(background_submenu_popup)
	get_popup().add_submenu_item("Change Background", "Background")
	get_popup().connect("id_pressed", self, "_on_Popup_id_pressed")
	background_submenu_popup.connect("index_pressed", self, "_on_Background_index_pressed")
	for hdr in hdrs:
		background_submenu_popup.add_item(hdr)


func _on_Popup_id_pressed(_id : int) -> void:
	show_background = not show_background
	get_popup().set_item_checked(0, show_background)
	emit_signal("show_background_toggled")


func _on_Background_index_pressed(index : int) -> void:
	emit_signal("hdr_selected", load(hdrs[background_submenu_popup.get_item_text(index)]))
