extends HBoxContainer

"""
An item in a `PropertyPanel`

Contains a `name_label` and the `property_control` the `property` returns.
Emmits the `property_changed` signal when the `property_control`
emitted the `changed_signal` the `property` specified.
"""

signal property_changed

var property : Property
var property_control : Control

const Property = preload("res://addons/property_panel/properties.gd").Property

onready var name_label : Label = $Name

func setup(_property : Property) -> void:
	property = _property
	name_label.text = property.name
	property_control = property._get_control()
	property_control.size_flags_horizontal = SIZE_EXPAND_FILL
	property_control.size_flags_vertical = SIZE_EXPAND_FILL
	property_control.rect_min_size.x = 60
	property_control.set_drag_forwarding(self)
	# this is a little hacky; since the argument count
	# of signal callbacks have to be a exactly right,
	# "pad" the call with the ´binds´ argument of ´connect´
	var arg_count := -1
	for signal_info in property_control.get_signal_list():
		if signal_info.name == property.changed_signal:
			arg_count = 5 - signal_info.args.size()
	var args := []
	for i in arg_count:
		args.append(1)
	property_control.connect(property.changed_signal, self, "_on_PropertyControl_changed", args)
	add_child(property_control)


func get_value():
	return property._get_value(property_control)


func set_value(to) -> void:
	property._set_value(property_control, to)


func _on_PropertyControl_changed(_a, _b, _c, _d, _e):
	emit_signal("property_changed")


func can_drop_data_fw(_position : Vector2, data, _control : Control) -> bool:
	return property._can_drop_data(property_control, data)


func drop_data_fw(_position : Vector2, data, _control : Control) -> void:
	property._drop_data(property_control, data)
	emit_signal("property_changed")
