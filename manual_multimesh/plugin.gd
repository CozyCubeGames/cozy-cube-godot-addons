@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("ManualMultiMeshInstance3D", "MultiMeshInstance3D", preload("uid://bt3fnycwurouo"), null)
	add_custom_type("ManualMultiMeshChild3D", "Node3D", preload("uid://bq4hgulf0pjpt"), null)


func _exit_tree() -> void:

	remove_custom_type("ManualMultiMeshInstance3D")
	remove_custom_type("ManualMultiMeshChild3D")
