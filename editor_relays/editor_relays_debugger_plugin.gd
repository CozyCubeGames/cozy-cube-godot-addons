@tool
class_name EditorRelaysDebuggerPlugin
extends EditorDebuggerPlugin


var _relays: Array[EditorRelay]


func _has_capture(capture: String) -> bool:

	return capture.begins_with("relay-")


func _capture(msg: String, data: Array, session_id: int) -> bool:

	var msg_tokens := msg.trim_prefix("relay-").split(":")
	for relay in _relays:
		if is_instance_valid(relay) and relay.is_inside_tree() and relay.message_group == msg_tokens[0]:
			relay.message_received_from_game.emit(msg_tokens[1], data)
	return true


func _register_relay(relay: EditorRelay) -> void:

	if not _relays.has(relay):
		_relays.append(relay)


func _unregister_relay(relay: EditorRelay) -> void:

	_relays.erase(relay)
