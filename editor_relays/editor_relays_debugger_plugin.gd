@tool
class_name EditorRelaysDebuggerPlugin
extends EditorDebuggerPlugin


var _relays: Array[EditorRelay]
var _debug_session_started: bool


func _has_capture(capture: String) -> bool:

	return capture.begins_with("relay-")


func _setup_session(session_id: int) -> void:

	var session := get_session(session_id)
	session.started.connect(_on_session_started)
	session.stopped.connect(_on_session_stopped)


func _capture(msg: String, data: Array, session_id: int) -> bool:

	var msg_tokens := msg.trim_prefix("relay-").split(":")
	for relay in _relays:
		if is_instance_valid(relay) and (relay.is_inside_tree() or relay.active_outside_tree) and relay.channel == msg_tokens[0]:
			relay.message_received_from_game.emit(msg_tokens[1], data)
	return true


func _register_relay(relay: EditorRelay) -> void:

	if not _relays.has(relay):
		_relays.append(relay)


func _unregister_relay(relay: EditorRelay) -> void:

	_relays.erase(relay)


func _on_session_started() -> void:

	if _debug_session_started:
		return

	_debug_session_started = true

	for relay in _relays:
		if is_instance_valid(relay) and not relay.is_queued_for_deletion():
			relay.game_connected.emit()


func _on_session_stopped() -> void:

	if not _debug_session_started:
		return

	_debug_session_started = false

	for relay in _relays:
		if is_instance_valid(relay) and not relay.is_queued_for_deletion():
			relay.game_disconnected.emit()
