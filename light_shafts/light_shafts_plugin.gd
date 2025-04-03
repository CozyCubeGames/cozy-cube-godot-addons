@tool
class_name LightShaftsPlugin
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("LightShaft3D", "MeshInstance3D", preload("uid://bslqtjuwuelro"), null)


func _exit_tree() -> void:

	remove_custom_type("LightShaft3D")
