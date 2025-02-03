@tool
class_name DoodleTexturePlugin
extends EditorPlugin


static var instance: DoodleTexturePlugin

var inspector_plugin := DoodleTextureInspectorPlugin.new()


func _enter_tree() -> void:

	instance = self

	add_custom_type("DoodleTexture", "PortableCompressedTexture2D", preload("res://addons/doodle_texture/doodle_texture.gd"), null)
	add_inspector_plugin(inspector_plugin)


func _exit_tree() -> void:

	remove_custom_type("DoodleTexture")
	remove_inspector_plugin(inspector_plugin)
