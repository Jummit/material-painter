extends Button

signal changed

var path := ""

func _pressed():
	$FileDialog.popup_centered()


func _on_FileDialog_file_selected(selected_path : String):
	path = selected_path
	emit_signal("changed")
