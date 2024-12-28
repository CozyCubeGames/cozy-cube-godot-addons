@tool
extends EditorPlugin


var _toggle_button: Button
var _old_world_2d: World2D


func _enter_tree() -> void:

	_toggle_button = Button.new()
	_toggle_button.toggle_mode = true
	_toggle_button.theme_type_variation = "FlatButton"
	_toggle_button.icon = EditorInterface.get_editor_theme().get_icon("2D", "EditorIcons")
	_toggle_button.tooltip_text = "Preview 2D"
	_toggle_button.toggled.connect(_on_toggled)

	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toggle_button)


func _exit_tree() -> void:

	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _toggle_button)

	_toggle_button.toggled.disconnect(_on_toggled)
	_toggle_button.free()


func _on_toggled(on: bool) -> void:

	if on:
		_old_world_2d = EditorInterface.get_editor_viewport_3d().world_2d
		EditorInterface.get_editor_viewport_3d().world_2d = EditorInterface.get_editor_viewport_2d().world_2d
		EditorInterface.get_editor_viewport_3d().size_2d_override = Vector2i(
				ProjectSettings.get_setting_with_override("display/window/size/viewport_width"),
				ProjectSettings.get_setting_with_override("display/window/size/viewport_height"))
		EditorInterface.get_editor_viewport_3d().size_2d_override_stretch = true
	else:
		EditorInterface.get_editor_viewport_3d().world_2d = _old_world_2d
		EditorInterface.get_editor_viewport_3d().size_2d_override = Vector2i.ZERO
		EditorInterface.get_editor_viewport_3d().size_2d_override_stretch = false
