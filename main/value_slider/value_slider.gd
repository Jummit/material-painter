tool
extends VBoxContainer

export var value_name : String setget set_value_name
export var value : float setget set_value
export var min_value : float setget set_min_value
export var max_value : float setget set_max_value

onready var value_slider : HSlider = $ValueSlider
onready var value_edit : LineEdit = $HBoxContainer/ValueEdit
onready var name_label : Label = $HBoxContainer/NameLabel

func set_value_name(to) -> void:
	if not is_inside_tree():
		yield(self, "tree_entered")
		yield(get_tree(), "idle_frame")
	value_name = to
	name_label.text = to


func set_value(to) -> void:
	if not is_inside_tree():
		yield(self, "tree_entered")
		yield(get_tree(), "idle_frame")
	value = to
	value_slider.value = to
	value_edit.text = str(to)


func set_min_value(to) -> void:
	if not is_inside_tree():
		yield(self, "tree_entered")
		yield(get_tree(), "idle_frame")
	min_value = to
	value_slider.min_value = to


func set_max_value(to) -> void:
	if not is_inside_tree():
		yield(self, "tree_entered")
		yield(get_tree(), "idle_frame")
	max_value = to
	value_slider.max_value = to


func _on_ValueSlider_value_changed(new_value : float) -> void:
	set_value(new_value)


func _on_ValueEdit_text_changed(new_text : String) -> void:
	set_value(float(new_text))
