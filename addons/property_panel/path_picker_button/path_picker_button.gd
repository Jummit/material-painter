extends Button

signal changed

var path := "" setget set_path

func _pressed():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(selected_path : String):
	self.path = selected_path
	emit_signal("changed")


func set_path(to : String):
	text = to.get_file()
	path = to
