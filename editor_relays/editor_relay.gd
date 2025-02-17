@tool
class_name EditorRelay
extends Node


signal message_received_from_game(message: StringName, data: Array)
signal message_received_from_editor(message: StringName, data: Array)


## All relays in the same message group will process the same messages. By default, all relays is under the same global group and will process all messages, so make sure to assign different group names if you want to isolate them.
@export var message_group: StringName:
	get: return message_group
	set(value):
		var old_message_group := message_group
		message_group = value
		if not Engine.is_editor_hint():
			if is_node_ready():
				EngineDebugger.unregister_message_capture("relay-" + old_message_group)
				EngineDebugger.register_message_capture("relay-" + message_group, _on_message_captured)


var _plugin: EditorRelaysDebuggerPlugin


func _ready() -> void:

	if Engine.is_editor_hint():
		if is_instance_valid(EditorRelaysPlugin._instance):
			_plugin = EditorRelaysPlugin._instance._debugger_plugin
			if is_instance_valid(_plugin):
				_plugin._register_relay(self)
	else:
		EngineDebugger.register_message_capture("relay-" + message_group, _on_message_captured)


func _notification(what: int) -> void:

	if what == NOTIFICATION_PREDELETE:

		if Engine.is_editor_hint():
			if is_instance_valid(_plugin):
				_plugin._unregister_relay(self)
		else:
			EngineDebugger.unregister_message_capture("relay-" + message_group)


func send_message_to_game(message: StringName, data: Array = []) -> void:

	if not Engine.is_editor_hint():
		return

	if is_instance_valid(_plugin):
		var session := _plugin.get_session(0)
		if is_instance_valid(session) and session.is_active():
			session.send_message("relay-" + message_group + ":" + message, data)


func send_message_to_editor(message: StringName, data: Array = []) -> void:

	if Engine.is_editor_hint():
		return

	EngineDebugger.send_message("relay-" + message_group + ":" + message, data)


func _on_message_captured(message: String, data: Array) -> bool:

	if is_inside_tree():
		message_received_from_editor.emit(message, data)
		return true
	return false
