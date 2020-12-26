extends OptionButton

func _ready():
	Globals.connect("current_file_changed", self, "_on_Globals_current_file_changed")


func _on_Globals_current_file_changed() -> void:
	clear()
	for material_num in Globals.current_file.layer_materials.size():
		add_item("Material %s" % material_num)
