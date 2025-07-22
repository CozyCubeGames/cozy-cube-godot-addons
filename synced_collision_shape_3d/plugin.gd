@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("SyncedCollisionShape3D", "CollisionShape3D", preload("synced_collision_shape_3d.gd"), null)


func _exit_tree() -> void:

	remove_custom_type("SyncedCollisionShape3D")
