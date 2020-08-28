extends Panel

onready var properties_container : VBoxContainer = $Properties

signal values_changed

class Property:
# warning-ignore:unused_class_variable
	var name : String
	var changed_signal : String
	var property_variable : String
	
	func _init(_changed_signal : String, _property_variable : String):
		changed_signal = _changed_signal
		property_variable = _property_variable
	
	func get_control() -> Control:
		return Control.new()
	
	func get_value(control : Control):
		return control.get(property_variable)
	
	func set_value(control : Control, to) -> void:
		control.set(property_variable, to)

class EnumProperty extends Property:
	var choices : PoolStringArray
	
	func _init(_name : String, _choices : PoolStringArray).("item_selected", ""):
		name = _name
		choices = _choices
	
	func get_control() -> Control:
		var option_button := OptionButton.new()
		for choice in choices:
			option_button.get_popup().add_item(choice)
		option_button.selected = 0
		return option_button
	
	func get_value(control : Control):
		return choices[control.selected]
	
	func set_value(control : Control, to) -> void:
		control.selected = (choices as Array).find(to)

class StringProperty extends Property:
	func _init(_name : String).("text_changed", "text"):
		name = _name
	
	func get_control() -> Control:
		return LineEdit.new()

class BoolProperty extends Property:
	func _init(_name : String).("toggled", "pressed"):
		name = _name
	
	func get_control() -> Control:
		return CheckBox.new()

class RangeProperty extends Property:
	var from : float
	var to : float
	var step : float
	func _init(_step : float).("value_changed", "value"):
		_step = step
	
	func get_control() -> Control:
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
	
	func get_control() -> Control:
		return ColorPickerButton.new()

class FilePathProperty extends Property:
	func _init(_name : String).("changed", "path"):
		name = _name
	
	func get_control() -> Control:
		return load("res://addons/property_panel/path_picker_button/path_picker_button.tscn").instance() as Control

var properties := [] setget set_properties


func _ready():
	build()


func set_properties(to):
	properties = to
	build()


func build() -> void:
	for property_container in properties_container.get_children():
		# use ´free´ instead of ´queue_free´ to immediatly remove nodes
		# because otherwise duplicate properties get automatically renamed
		property_container.free()
	
	for property in properties:
		property = property as Property
		var property_container : HBoxContainer = load("res://addons/property_panel/property_container/property_container.tscn").instance()
		property_container.name = property.name
		property_container.connect("property_changed", self, "_on_Property_changed")
		properties_container.add_child(property_container)
		property_container.setup(property)


func get_property_value(property_name : String):
	return properties_container.get_node(property_name).get_value()


func get_property_values() -> Dictionary:
	var values := {}
	for property_container in properties_container.get_children():
		values[property_container.name] = get_property_value(property_container.name)
	return values


func load_values(values : Dictionary) -> void:
	for value in values.keys():
		properties_container.get_node(value).set_value(values[value])


func _on_Property_changed():
	emit_signal("values_changed")
