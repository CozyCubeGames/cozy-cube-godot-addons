@tool
class_name EditorRelaysExample
extends Node


func _ready() -> void:

	if Engine.is_editor_hint():
		get_window().size_changed.connect(_send_size_to_game)
	else:
		$relay.send_message_to_editor("request_size")


func _send_size_to_game() -> void:

	$relay.send_message_to_game("size", [get_window().size])


func _on_message_received_from_editor(message: StringName, params: Array) -> void:

	if message == "size":
		%size_label.text = "Editor Size: " + str(params[0])


func _on_message_received_from_game(message: StringName, params: Array) -> void:

	match message:
		"request_size": _send_size_to_game()
		"minimize": get_window().mode = Window.MODE_MINIMIZED
		"restore": get_window().mode = Window.MODE_WINDOWED
		"maximize": get_window().mode = Window.MODE_MAXIMIZED


func _on_minimize_button_pressed() -> void:

	$relay.send_message_to_editor("minimize")


func _on_restore_button_pressed() -> void:

	$relay.send_message_to_editor("restore")


func _on_maximize_button_pressed() -> void:

	$relay.send_message_to_editor("maximize")
