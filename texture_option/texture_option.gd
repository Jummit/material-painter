extends PanelContainer

onready var clear_button : Button = $HBoxContainer/ClearButton
onready var texture_popup_menu : MenuButton = $HBoxContainer/TexturePopupMenu
onready var new_button : Button = $HBoxContainer/NewButton
onready var name_edit : LineEdit = $HBoxContainer/NameEdit
onready var texture_popup : PopupMenu = texture_popup_menu.get_popup()

const LayerTexture = preload("res://texture_layers/layer_texture.gd")

signal selected
signal changed

var selected_texture : LayerTexture setget set_selected_texture

func _ready():
	texture_popup.connect("id_pressed", self, "_on_TextureMenuPopup_id_pressed")


func _make_custom_tooltip(_for_text : String):
	var tooltip : PanelContainer = preload("res://texture_layers/texture_tooltip/texture_tool_tip.tscn").instance()
	if selected_texture:
		tooltip.get_node("VBoxContainer/TextureRect").texture = selected_texture.result
		tooltip.get_node("VBoxContainer/Name").text = selected_texture.name
		return tooltip


func set_selected_texture(to : LayerTexture):
	var has_texture := to != null
	clear_button.visible = has_texture
	name_edit.visible = has_texture
	new_button.visible = not has_texture
	selected_texture = to
	if has_texture:
		name_edit.text = to.name
	emit_signal("changed")


func _on_NewButton_pressed():
	var texture := LayerTexture.new()
	TextureManager.textures.append(texture)
	self.selected_texture = texture


func _on_ClearButton_pressed():
	self.selected_texture = null


func _on_TextureMenuPopup_id_pressed(id : int):
	self.selected_texture = texture_popup.get_item_metadata(id)


func _on_TexturePopupMenu_about_to_show():
	texture_popup.clear()
	for texture in TextureManager.textures:
		texture = texture as LayerTexture
		texture_popup.add_item(texture.name)
		texture_popup.set_item_metadata(texture_popup.get_item_count() - 1, texture)


func _on_NameEdit_text_changed(new_text : String):
	selected_texture.name = new_text


func _on_NameEdit_focus_entered():
	emit_signal("selected")
