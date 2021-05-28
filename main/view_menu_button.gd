extends MenuButton

"""
A menu containing view related options

Used to switch backgrounds.
HDRIs used are from `https://hdrihaven.com/`.
"""

var show_background := false

var layouts_submenu_popup := PopupMenu.new()
var blur_submenu_popup := PopupMenu.new()

enum Item {
	SHOW_BACKGROUND,
	BACKGROUND_BLUR,
	ENABLE_SHADOWS,
	VIEW_RESULTS,
	FULLSCREEN,
	UPDATE_ICONS,
	LAYOUTS,
}

signal show_background_toggled
signal background_blur_selected(amount)
signal layout_selected(layout)
signal save_layout_selected
signal update_icons_toggled

const ShortcutUtils = preload("res://utils/shortcut_utils.gd")

onready var results_item_list_window : Panel = $"../../../Control/HBoxContainer/ResultsWindow"
onready var directional_light : DirectionalLight = $"../../../Control/HBoxContainer/HSplitContainer/VBoxContainer/VBoxContainer/HBoxContainer/ViewportTabContainer/3DViewportWindow/3DViewport/Viewport/DirectionalLight"

func _ready() -> void:
	var popup := get_popup()
	popup.add_check_item("Show Background", Item.SHOW_BACKGROUND)
	popup.set_item_shortcut(Item.SHOW_BACKGROUND, ShortcutUtils.shortcut(KEY_B))
	
	blur_submenu_popup.name = "BackgroundBlur"
	for blur_amount in 6:
		blur_submenu_popup.add_item("Amount " + str(blur_amount))
	
	popup.add_submenu_item("Background Blur", "BackgroundBlur")
	get_popup().add_child(blur_submenu_popup)
	blur_submenu_popup.connect("index_pressed", self, "_on_Blur_index_pressed")
	
	popup.add_check_item("Enable Shadows", Item.ENABLE_SHADOWS)
	popup.set_item_tooltip(Item.ENABLE_SHADOWS, "Enable real-time shadows")
	popup.connect("id_pressed", self, "_on_Popup_id_pressed")
	popup.add_check_item("View results", Item.VIEW_RESULTS)
	popup.set_item_shortcut(Item.VIEW_RESULTS, ShortcutUtils.shortcut(KEY_R))
	popup.add_check_item("Fullscreen", Item.FULLSCREEN)
	popup.set_item_shortcut(Item.FULLSCREEN, ShortcutUtils.shortcut(KEY_F11))
	
	popup.add_check_item("Update Layer Icons", Item.UPDATE_ICONS)
	popup.set_item_tooltip(Item.UPDATE_ICONS, "Disable this if generating the material is slow.")
	popup.set_item_checked(Item.UPDATE_ICONS, true)
	popup.set_item_shortcut(Item.UPDATE_ICONS, ShortcutUtils.shortcut(KEY_I))
	
	popup.add_submenu_item("Layouts", "Layouts")
	layouts_submenu_popup.name = "Layouts"
	get_popup().add_child(layouts_submenu_popup)
	layouts_submenu_popup.connect("id_pressed", self, "_on_Layouts_id_pressed")


func update_layout_options() -> void:
	layouts_submenu_popup.clear()
	layouts_submenu_popup.add_item("Save current")
	layouts_submenu_popup.add_separator()
	for layout_file in _get_files("user://layouts"):
		layouts_submenu_popup.add_item(layout_file.get_basename())
		layouts_submenu_popup.set_item_metadata(
				layouts_submenu_popup.get_item_count() - 1, layout_file)


func _on_Popup_id_pressed(id : int) -> void:
	match id:
		Item.ENABLE_SHADOWS:
			var checked := get_popup().is_item_checked(Item.ENABLE_SHADOWS)
			directional_light.shadow_enabled = not checked
			get_popup().set_item_checked(Item.ENABLE_SHADOWS, not checked)
		Item.SHOW_BACKGROUND:
			show_background = not show_background
			get_popup().set_item_checked(get_popup().get_item_index(
					Item.SHOW_BACKGROUND), show_background)
			emit_signal("show_background_toggled")
		Item.FULLSCREEN:
			OS.window_fullscreen = not OS.window_fullscreen
			get_popup().set_item_checked(Item.FULLSCREEN, OS.window_fullscreen)
		Item.VIEW_RESULTS:
			results_item_list_window.visible = not results_item_list_window.visible
			get_popup().set_item_checked(get_popup().get_item_index(
					Item.VIEW_RESULTS), results_item_list_window.visible)
		Item.UPDATE_ICONS:
			get_popup().set_item_checked(Item.UPDATE_ICONS,
					not get_popup().is_item_checked(Item.UPDATE_ICONS))
			emit_signal("update_icons_toggled")


func _on_Layouts_id_pressed(id : int) -> void:
	if id == 0:
		emit_signal("save_layout_selected")
	else:
		emit_signal("layout_selected",
			layouts_submenu_popup.get_item_metadata(id))


func _on_Blur_index_pressed(index : int) -> void:
	emit_signal("background_blur_selected", index)


func _get_files(path : String) -> PoolStringArray:
	var files : PoolStringArray = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		files.append(file_name)
		file_name = dir.get_next()
	return files
