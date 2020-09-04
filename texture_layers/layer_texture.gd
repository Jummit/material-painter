extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a result which is updated when settings of the layers change.
"""

# warning-ignore:unused_class_variable
export var layers : Array
# warning-ignore:unused_class_variable
export var name := "Untitled Texture"
# warning-ignore:unused_class_variable
var result : Texture
