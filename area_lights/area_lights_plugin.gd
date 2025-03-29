@tool
class_name AreaLightsPlugin
extends EditorPlugin


var _gizmo_plugin := preload("uid://cpho3xqjfbvrg").new()


func _enter_tree() -> void:

	add_custom_type("AreaLight3D", "Node3D", preload("uid://fpt3jomast5j"), preload("uid://tumm33aigvqn"))
	add_node_3d_gizmo_plugin(_gizmo_plugin)


func _exit_tree() -> void:

	remove_custom_type("AreaLight3D")
	remove_node_3d_gizmo_plugin(_gizmo_plugin)
