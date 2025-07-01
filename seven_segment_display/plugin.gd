@tool
extends EditorPlugin


func _enter_tree() -> void:

	add_custom_type("SevenSegmentDisplay", "MultiMeshInstance3D", preload("uid://bx0rnfjvk0gkd"), preload("uid://de6u2e3cio2mo"))
	add_custom_type("SevenSegmentDigitMesh", "ArrayMesh", preload("uid://cc5dvvgshd4vl"), preload("uid://dnospgbp181xp"))


func _exit_tree() -> void:

	remove_custom_type("SevenSegmentDisplay")
	remove_custom_type("SevenSegmentDigitMesh")
