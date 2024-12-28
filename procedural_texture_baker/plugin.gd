@tool
extends EditorPlugin


var converter_plugin: EditorResourceConversionPlugin = preload("res://addons/procedural_texture_baker/procedural_texture_converter_plugin.gd").new()


func _enter_tree() -> void:

	add_resource_conversion_plugin(converter_plugin)


func _exit_tree() -> void:

	remove_resource_conversion_plugin(converter_plugin)
