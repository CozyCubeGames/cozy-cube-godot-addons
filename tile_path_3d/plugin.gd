@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("TilePath3D", "Path3D", preload("tile_path_3d.gd"), null)


func _exit_tree() -> void:

	remove_custom_type("TilePath3D")
