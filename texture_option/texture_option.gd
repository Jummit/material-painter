extends PanelContainer

onready var clear_button : Button = $HBoxContainer/ClearButton
onready var texture_popup_menu : MenuButton = $HBoxContainer/TexturePopupMenu
onready var new_button : Button = $HBoxContainer/NewButton
onready var name_edit : LineEdit = $HBoxContainer/NameEdit
onready var texture_popup : PopupMenu = texture_popup_menu.get_popup()

const TextureMap = preload("res://texture_map.gd")

signal changed

var selected_texture : TextureMap setget set_selected_texture

func _ready():
	texture_popup.connect("id_pressed", self, "_on_TextureMenuPopup_id_pressed")


func set_selected_texture(to : TextureMap):
	var has_texture := to != null
	clear_button.visible = has_texture
	name_edit.visible = has_texture
	new_button.visible = not has_texture
	selected_texture = to
	if has_texture:
		name_edit.text = to.name
	emit_signal("changed")


func _on_NewButton_pressed():
	var texture := TextureMap.new("Untitled Texture")
	TextureManager.textures.append(texture)
	self.selected_texture = texture


func _on_ClearButton_pressed():
	self.selected_texture = null


func _on_TextureMenuPopup_id_pressed(id : int):
	self.selected_texture = texture_popup.get_item_metadata(id)


func _on_TexturePopupMenu_about_to_show():
	texture_popup.clear()
	for texture in TextureManager.textures:
		texture = texture as TextureMap
		texture_popup.add_item(texture.name)
		texture_popup.set_item_metadata(texture_popup.get_item_count() - 1, texture)
