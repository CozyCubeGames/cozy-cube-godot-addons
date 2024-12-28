@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("TransformCluster3D", "Node", preload("transform_cluster_3d.gd"), preload("transform_cluster_3d.svg"))


func _exit_tree() -> void:

	remove_custom_type("TransformCluster3D")
