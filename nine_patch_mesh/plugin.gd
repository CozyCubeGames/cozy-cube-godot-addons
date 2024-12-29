@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("NinePatchMesh", "ArrayMesh", preload("nine_patch_mesh.gd"), preload("NinePatchMesh.svg"))
	add_custom_type("TwentySevenPatchMesh", "ArrayMesh", preload("twenty_seven_patch_mesh.gd"), preload("NinePatchMesh.svg"))


func _exit_tree() -> void:

	remove_custom_type("NinePatchMesh")
	remove_custom_type("TwentySevenPatchMesh")
