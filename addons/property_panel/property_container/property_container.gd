extends HBoxContainer

onready var name_label : Label = $Name

const Property = preload("res://addons/property_panel/property_panel.gd").Property

signal property_changed

var property : Property
var property_control : Control

func setup(_property : Property) -> void:
	property = _property
	name_label.text = property.name
	property_control = property.get_control()
	property_control.size_flags_horizontal = SIZE_EXPAND_FILL
	property_control.size_flags_vertical = SIZE_EXPAND_FILL
	var arg_count := -1
	for signal_info in property_control.get_signal_list():
		if signal_info.name == property.changed_signal:
			arg_count = 5 - signal_info.args.size()
	var args := []
	for i in arg_count:
		args.append(1)
	property_control.connect(property.changed_signal, self, "_on_Property_changed", args)
	add_child(property_control)


func get_value():
	return property_control.get(property.property_variable)


func set_value(to):
	property_control.set(property.property_variable, to)


func _on_Property_changed(_a, _b, _c, _d, _e):
	emit_signal("property_changed")
