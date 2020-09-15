extends Resource

"""
A texture made up of blending `TextureLayer`s stored in the `layers` array

Stores a result which is updated when settings of the layers change.
"""

# warning-ignore-all:unused_class_variable
export var layers : Array
export var name := "Untitled Texture"
var result : Texture
