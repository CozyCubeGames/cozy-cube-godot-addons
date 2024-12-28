@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("ControlProxy3D", "ControlProxy", preload("control_proxy_3d.gd"), null)


func _exit_tree() -> void:

	remove_custom_type("ControlProxy3D")
