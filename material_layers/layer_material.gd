extends Resource

"""
A material made out of several MaterialLayers

`layers` contains the `MaterialLayers`, each of which can have multiple channels enabled. When baking the results, all `LayerTexture`s of each channel are blended together and stored in the `results` `Dictionary`. It stores the blended `ImageTexture`s with the channel names as keys.
"""

# warning-ignore:unused_class_variable
export var layers : Array
# warning-ignore:unused_class_variable
var results : Dictionary
