@tool
class_name EditorRelay
extends Node


signal message_received_from_game(message: StringName, data: Array)
signal message_received_from_editor(message: StringName, data: Array)


## All relays on the same channel will process the same messages. By default, all relays is under the same global channel and will process all messages, so make sure to assign different channel names if you want to isolate them.
@export var channel: StringName:
	get: return channel
	set(value):
		var old_channel := channel
		channel = value
		if not Engine.is_editor_hint():
			if is_node_ready():
				EngineDebugger.unregister_message_capture("relay-" + old_channel)
				EngineDebugger.register_message_capture("relay-" + channel, _on_message_captured)
## If [code]true[/code], this relay remains active if removed from the scene tree.
@export var active_outside_tree: bool

var _plugin: EditorRelaysDebuggerPlugin


func _ready() -> void:

	if Engine.is_editor_hint():
		if is_instance_valid(EditorRelaysPlugin._instance):
			_plugin = EditorRelaysPlugin._instance._debugger_plugin
			if is_instance_valid(_plugin):
				_plugin._register_relay(self)
	else:
		EngineDebugger.register_message_capture("relay-" + channel, _on_message_captured)


func _notification(what: int) -> void:

	if what == NOTIFICATION_PREDELETE:

		if Engine.is_editor_hint():
			if is_instance_valid(_plugin):
				_plugin._unregister_relay(self)
		else:
			EngineDebugger.unregister_message_capture("relay-" + channel)


func send_message_to_game(message: StringName, data: Array = []) -> void:

	if not Engine.is_editor_hint():
		return

	if is_instance_valid(_plugin):
		var session := _plugin.get_session(0)
		if is_instance_valid(session) and session.is_active():
			session.send_message("relay-" + channel + ":" + message, data)


func send_message_to_editor(message: StringName, data: Array = []) -> void:

	if Engine.is_editor_hint():
		return

	EngineDebugger.send_message("relay-" + channel + ":" + message, data)


func _on_message_captured(message: String, data: Array) -> bool:

	if active_outside_tree or is_inside_tree():
		message_received_from_editor.emit(message, data)
		return true
	return false
