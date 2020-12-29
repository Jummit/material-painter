"""
All properties used to edit values in a `PropertyPanel`

Each property can create a `Control` and specifies the signal that control emits
when it changed. It also specifies which member of the control is the resulting value.
"""

class Property:
# warning-ignore:unused_class_variable
	var name : String
	var changed_signal : String
	var property_variable : String
	
	func _init(_changed_signal : String, _property_variable : String):
		changed_signal = _changed_signal
		property_variable = _property_variable
	
	func _get_control() -> Control:
		return Control.new()
	
	func _get_value(control : Control):
		return control.get(property_variable)
	
	func _set_value(control : Control, to) -> void:
		control.set(property_variable, to)
	
	func _can_drop_data(control : Control, data) -> bool:
		return typeof(data) == typeof(_get_value(control))
	
	func _drop_data(control : Control, data) -> void:
		_set_value(control, data)

class EnumProperty extends Property:
	var choices : PoolStringArray
	
	func _init(_name : String, _choices : PoolStringArray).("item_selected", ""):
		name = _name
		choices = _choices
	
	func _get_control() -> Control:
		var option_button := OptionButton.new()
		for choice in choices:
			option_button.get_popup().add_item(choice)
		option_button.selected = 0
		return option_button
	
	func _get_value(control : Control):
		return choices[control.selected]
	
	func _set_value(control : Control, to) -> void:
		control.selected = (choices as Array).find(to)

class StringProperty extends Property:
	func _init(_name : String).("text_changed", "text"):
		name = _name
	
	func _get_control() -> Control:
		return LineEdit.new()

class BoolProperty extends Property:
	func _init(_name : String).("toggled", "pressed"):
		name = _name
	
	func _get_control() -> Control:
		return CheckBox.new()

class RangeProperty extends Property:
	var from : float
	var to : float
	var step : float
	func _init(_step : float).("value_changed", "value"):
		_step = step
	
	func _get_control() -> Control:
		var slider := HSlider.new()
		slider.min_value = from
		slider.max_value = to
		slider.step = step
#		slider.tick_count = 100
		return slider

class IntProperty extends RangeProperty:
	func _init(_name : String, _from : float, _to : float).(1):
		name = _name
		from = _from
		to = _to

class FloatProperty extends RangeProperty:
	func _init(_name : String, _from : float, _to : float).(0.01):
		name = _name
		from = _from
		to = _to

class ColorProperty extends Property:
	func _init(_name : String).("color_changed", "color"):
		name = _name
	
	func _get_control() -> Control:
		return ColorPickerButton.new()

class FilePathProperty extends Property:
	func _init(_name : String).("changed", "path"):
		name = _name
	
	func _get_control() -> Control:
		return preload("res://addons/property_panel/path_picker_button/path_picker_button.tscn").instance() as Control
