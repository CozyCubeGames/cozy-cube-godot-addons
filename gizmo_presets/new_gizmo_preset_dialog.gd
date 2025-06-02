@tool
class_name NewGizmoPresetDialog
extends ConfirmationDialog


@export var preset_name_field: LineEdit


func _ready() -> void:

	get_ok_button().disabled = true
	preset_name_field.grab_focus()


func get_preset_name() -> String:

	return preset_name_field.text


func _on_preset_name_field_text_changed(new_text: String) -> void:

	get_ok_button().disabled = new_text.strip_edges().is_empty()
