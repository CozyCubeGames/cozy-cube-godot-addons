@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("Line3D", "MeshInstance3D", preload("line_3d.gd"), preload("line_3d.svg"))
	add_custom_type("Trail3D", "Line3D", preload("trail_3d.gd"), preload("line_3d.svg"))


func _exit_tree() -> void:

	pass
