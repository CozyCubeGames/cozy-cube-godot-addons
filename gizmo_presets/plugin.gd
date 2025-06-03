@tool
extends EditorPlugin


signal confirmation_dialog_closed(result: bool)
signal new_preset_dialog_closed(preset_name: String)

const PRESETS_SETTING_NAME: String = "editor/cozy_cube/gizmo_presets"
const PRESETS_SEPARATOR_ID: int = 25763459
const LOAD_PRESET_SUBMENU_ID: int = PRESETS_SEPARATOR_ID + 1
const SAVE_PRESET_SUBMENU_ID: int = PRESETS_SEPARATOR_ID + 2
const DELETE_PRESET_SUBMENU_ID: int = PRESETS_SEPARATOR_ID + 2
const SHOW_ALL_ID: int = 100
const HIDE_ALL_ID: int = 101
const XRAY_ALL_ID: int = 102
const NEW_PRESET_ID: int = 100
const DELETE_ALL_ID: int = 100

var _gizmos_menu: PopupMenu
var _apply_preset_menu: PopupMenu
var _save_preset_menu: PopupMenu
var _delete_preset_menu: PopupMenu
var _confirmation_dialog: ConfirmationDialog
var _new_preset_dialog: NewGizmoPresetDialog


func _enter_tree() -> void:

	var dummy_control = Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dummy_control)

	var p: Node = dummy_control.get_parent()
	while p is not HFlowContainer:
		p = p.get_parent()
		if p == null:
			break

	var view_menu: PopupMenu

	var main_menu := p.get_child(0) as HBoxContainer
	if main_menu:
		for c in main_menu.get_children():
			if c is MenuButton and c.text == "View":
				view_menu = c.get_popup()
				break

	if view_menu:
		for i in view_menu.item_count:
			if view_menu.get_item_text(i) == "Gizmos":
				_gizmos_menu = view_menu.get_item_submenu_node(i)
				_gizmos_menu.about_to_popup.connect(_on_gizmos_about_to_popup)
				_gizmos_menu.popup_hide.connect(_on_gizmos_popup_hide)
				break

	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, dummy_control)
	dummy_control.free()

	if not ProjectSettings.has_setting(PRESETS_SETTING_NAME):
		ProjectSettings.set_setting(PRESETS_SETTING_NAME, {})
	ProjectSettings.set_as_internal(PRESETS_SETTING_NAME, true)


func _exit_tree() -> void:

	if is_instance_valid(_confirmation_dialog):
		_confirmation_dialog.free()
		_confirmation_dialog = null

	if _gizmos_menu:
		_gizmos_menu.about_to_popup.disconnect(_on_gizmos_about_to_popup)
		_gizmos_menu.popup_hide.disconnect(_on_gizmos_popup_hide)

	if _apply_preset_menu:
		_apply_preset_menu.free()
	if _save_preset_menu:
		_save_preset_menu.free()
	if _delete_preset_menu:
		_delete_preset_menu.free()


func _show_confirmation_dialog(title: String, text: String) -> bool:

	if is_instance_valid(_confirmation_dialog):
		_confirmation_dialog.free()
		_confirmation_dialog = null

	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.title = title
	_confirmation_dialog.dialog_text = text
	_confirmation_dialog.ok_button_text = "Yes"
	_confirmation_dialog.cancel_button_text = "No"
	_confirmation_dialog.confirmed.connect(_on_confirmation_dialog_confirmed)
	_confirmation_dialog.canceled.connect(_on_confirmation_dialog_canceled)

	EditorInterface.popup_dialog_centered(_confirmation_dialog)
	var result: bool = await confirmation_dialog_closed

	if is_instance_valid(_confirmation_dialog):
		_confirmation_dialog.queue_free()
		_confirmation_dialog = null

	return result


func _show_new_preset_dialog() -> String:

	if is_instance_valid(_new_preset_dialog):
		_new_preset_dialog.free()
		_new_preset_dialog = null

	_new_preset_dialog = load("uid://cm1cf82jitim5").instantiate()
	_new_preset_dialog.confirmed.connect(_on_new_preset_dialog_confirmed)
	_new_preset_dialog.canceled.connect(_on_new_preset_dialog_canceled)

	EditorInterface.popup_dialog_centered(_new_preset_dialog)
	var preset_name: String = await new_preset_dialog_closed

	if is_instance_valid(_new_preset_dialog):
		_new_preset_dialog.queue_free()
		_new_preset_dialog = null

	return preset_name


func _save_preset_at(idx: int) -> void:

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	if idx >= presets.size():
		return

	var keys := presets.keys()
	keys.sort()
	_save_preset(keys[idx] as String)


func _save_preset(preset_name: String) -> void:

	var presets = ProjectSettings.get_setting(PRESETS_SETTING_NAME)
	if presets is not Dictionary:
		presets = {}

	var preset := {}
	presets[preset_name] = preset

	for i in _gizmos_menu.item_count:
		if _gizmos_menu.get_item_multistate_max(i) != 3:
			continue
		var state := _gizmos_menu.get_item_multistate(i)
		if state == 1:
			continue
		preset[StringName(_gizmos_menu.get_item_text(i))] = state

	ProjectSettings.set_setting(PRESETS_SETTING_NAME, presets)
	ProjectSettings.save()


func _delete_preset_at(idx: int) -> void:

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	if idx >= presets.size():
		return

	var keys := presets.keys()
	keys.sort()
	presets.erase(keys[idx])
	ProjectSettings.set_setting(PRESETS_SETTING_NAME, presets)
	ProjectSettings.save()


func _on_gizmos_about_to_popup() -> void:

	if _gizmos_menu.get_item_index(PRESETS_SEPARATOR_ID) != -1:
		return

	_gizmos_menu.add_separator("", PRESETS_SEPARATOR_ID)

	_apply_preset_menu = PopupMenu.new()
	_apply_preset_menu.hide_on_item_selection = false
	_apply_preset_menu.about_to_popup.connect(_on_apply_preset_about_to_popup)
	_apply_preset_menu.id_pressed.connect(_on_apply_preset_pressed)
	_gizmos_menu.add_submenu_node_item("Apply Preset", _apply_preset_menu, LOAD_PRESET_SUBMENU_ID)

	_save_preset_menu = PopupMenu.new()
	_save_preset_menu.about_to_popup.connect(_on_save_preset_about_to_popup)
	_save_preset_menu.id_pressed.connect(_on_save_preset_pressed)
	_gizmos_menu.add_submenu_node_item("Save Preset", _save_preset_menu, SAVE_PRESET_SUBMENU_ID)

	_delete_preset_menu = PopupMenu.new()
	_delete_preset_menu.about_to_popup.connect(_on_delete_preset_about_to_popup)
	_delete_preset_menu.id_pressed.connect(_on_delete_preset_pressed)
	_gizmos_menu.add_submenu_node_item("Delete Preset", _delete_preset_menu, DELETE_PRESET_SUBMENU_ID)


func _on_gizmos_popup_hide() -> void:

	for id in [PRESETS_SEPARATOR_ID, LOAD_PRESET_SUBMENU_ID, SAVE_PRESET_SUBMENU_ID, DELETE_PRESET_SUBMENU_ID]:
		var idx := _gizmos_menu.get_item_index(id)
		if idx != -1:
			_gizmos_menu.remove_item(idx)

	if _apply_preset_menu:
		_apply_preset_menu.queue_free()
	if _save_preset_menu:
		_save_preset_menu.queue_free()
	if _delete_preset_menu:
		_delete_preset_menu.queue_free()


func _on_apply_preset_about_to_popup() -> void:

	_apply_preset_menu.clear()

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	if not presets.is_empty():
		var keys := presets.keys()
		keys.sort()
		for i in keys.size():
			_apply_preset_menu.add_item(keys[i], i)
		_apply_preset_menu.add_separator()

	_apply_preset_menu.add_item("Show All", SHOW_ALL_ID)
	_apply_preset_menu.add_item("Hide All", HIDE_ALL_ID)
	_apply_preset_menu.add_item("X-Ray All", XRAY_ALL_ID)


func _on_save_preset_about_to_popup() -> void:

	_save_preset_menu.clear()

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	if not presets.is_empty():
		var keys := presets.keys()
		keys.sort()
		for i in keys.size():
			_save_preset_menu.add_item(keys[i], i)
		_save_preset_menu.add_separator()

	_save_preset_menu.add_item("New Preset", NEW_PRESET_ID)


func _on_delete_preset_about_to_popup() -> void:

	_delete_preset_menu.clear()

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	if not presets.is_empty():
		var keys := presets.keys()
		keys.sort()
		for i in keys.size():
			_delete_preset_menu.add_item(keys[i], i)
		_delete_preset_menu.add_separator()

	_delete_preset_menu.add_item("Delete All", DELETE_ALL_ID)
	_delete_preset_menu.set_item_disabled(_delete_preset_menu.item_count - 1, presets.is_empty())


func _on_apply_preset_pressed(id: int) -> void:

	var presets: Dictionary = ProjectSettings.get_setting(PRESETS_SETTING_NAME, {})
	var preset: Dictionary

	if id < presets.size():
		var keys := presets.keys()
		keys.sort()
		preset = presets.get(keys[id], null)

	for i in _gizmos_menu.item_count:

		if _gizmos_menu.get_item_multistate_max(i) != 3:
			continue

		var target_state: int
		match id:
			SHOW_ALL_ID: target_state = 0
			HIDE_ALL_ID: target_state = 1
			XRAY_ALL_ID: target_state = 2
			_: target_state = preset.get(_gizmos_menu.get_item_text(i), 1)

		if target_state == _gizmos_menu.get_item_multistate(i):
			continue

		_gizmos_menu.set_item_multistate(i, (target_state + 2) % 3)
		_gizmos_menu.id_pressed.emit(_gizmos_menu.get_item_id(i))


func _on_save_preset_pressed(id: int) -> void:

	if id == NEW_PRESET_ID:
		var preset_name := await _show_new_preset_dialog()
		if preset_name.strip_edges().is_empty():
			return
		_save_preset(preset_name)
	else:
		_save_preset_at(id)


func _on_delete_preset_pressed(id: int) -> void:

	if id == DELETE_ALL_ID:
		if await _show_confirmation_dialog(
				"Delete All Gizmo Presets",
				"Delete all gizmo presets? This cannot be undone."):
			ProjectSettings.set_setting(PRESETS_SETTING_NAME, {})
			ProjectSettings.save()
	else:
		var preset_name := _delete_preset_menu.get_item_text(_delete_preset_menu.get_item_index(id))
		if await _show_confirmation_dialog(
				"Delete Gizmo Preset",
				"Delete gizmo preset \"" + preset_name + "\"? This cannot be undone."):
			_delete_preset_at(id)


func _on_confirmation_dialog_confirmed() -> void:

	confirmation_dialog_closed.emit(true)


func _on_confirmation_dialog_canceled() -> void:

	confirmation_dialog_closed.emit(false)


func _on_new_preset_dialog_confirmed() -> void:

	new_preset_dialog_closed.emit(_new_preset_dialog.get_preset_name())


func _on_new_preset_dialog_canceled() -> void:

	new_preset_dialog_closed.emit("")
