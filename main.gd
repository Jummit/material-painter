extends Control

onready var file_menu_button : MenuButton = $VBoxContainer/TopButtonBar/FileMenuButton
onready var material_layer_panel : VBoxContainer = $VBoxContainer/PanelContainer/LayerContainer/MaterialLayerPanel

const SaveFile = preload("res://save_file.gd")

var current_file : Resource = SaveFile.new()

func _ready():
	file_menu_button.get_popup().connect("id_pressed", self, "_on_FileMenu_id_pressed")
	material_layer_panel.editing_layer_material = current_file.layer_material


func _on_FileMenu_id_pressed(id : int):
	match id:
		0:
			current_file = SaveFile.new()
			material_layer_panel.editing_layer_material = current_file.layer_material
		1:
			load_material("res://save.tres")
		2:
			save_material("res://save.tres")


func load_material(path : String) -> void:
	current_file = load(path)
	material_layer_panel.editing_layer_material = current_file.layer_material


func save_material(path : String) -> void:
	ResourceSaver.save(path, current_file)
