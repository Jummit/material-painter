extends "res://addons/arrangable_tree/arrangable_tree.gd"

class TextureMap extends Resource:
#	export var 
	pass

class MaterialLayer extends Resource:
# warning-ignore:unused_class_variable
	export var mask : Resource
# warning-ignore:unused_class_variable
	export var textures : Array
	export var name := "Untitled Layer"


func _on_AddLayerButton_pressed():
	var new_layer := MaterialLayer.new()
	new_layer.name = str(rand_range(1, 20))
	layers.append(new_layer)
	update_tree()
