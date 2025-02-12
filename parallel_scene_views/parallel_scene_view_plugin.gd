@tool
class_name ParallelSceneViewPlugin
extends EditorPlugin


const BUTTON_SCN = preload("res://addons/parallel_scene_views/parallel_scene_view_button.tscn")

var _button: ParallelSceneViewButton
var _active_previews: Variant = null
var _previews_by_scene: Dictionary
var _previews_dirty_by_scene: Dictionary
var _dialog: EditorFileDialog
var _asking_idx: int

static var instance: ParallelSceneViewPlugin


func _enter_tree() -> void:

	if instance == null:
		instance = self

	_button = BUTTON_SCN.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _button)


func _exit_tree() -> void:

	for i in 4:
		_set_preview_visible(i, false)

	for scene_path in _previews_by_scene.keys():
		var previews = _previews_by_scene.get(scene_path, null)
		if not previews:
			continue
		for preview in previews:
			if is_instance_valid(preview):
				preview.free()

	_previews_by_scene.clear()
	_previews_dirty_by_scene.clear()

	if is_instance_valid(_button):
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, _button)
		_button.free()
		_button = null

	if is_instance_valid(_dialog):
		_dialog.free()
		_dialog = null

	if instance == self:
		instance = null


func _ready() -> void:

	_dialog = EditorFileDialog.new()
	_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	_dialog.add_filter("*.tscn, *.scn", "Scenes")
	_dialog.min_size = Vector2i(720, 480)
	_dialog.file_selected.connect(_on_dialog_file_selected)
	_dialog.canceled.connect(_on_dialog_canceled)

	if EditorInterface.get_edited_scene_root():
		_active_previews = _previews_by_scene.get_or_add(
				EditorInterface.get_edited_scene_root().scene_file_path,
				[null, null, null, null])

	scene_changed.connect(_on_scene_changed)
	scene_saved.connect(_on_scene_saved)
	scene_closed.connect(_on_scene_closed)


func has_parallel_scene(idx: int) -> bool:

	if not _active_previews:
		return false
	return is_instance_valid(_active_previews[idx])


func get_parallel_scene(idx: int) -> String:

	if not _active_previews:
		return ""
	var preview: Node = _active_previews[idx]
	if is_instance_valid(preview):
		return preview.scene_file_path
	return ""


func ask_for_parallel_scene(idx: int) -> void:

	if not _active_previews:
		return

	_asking_idx = idx
	EditorInterface.popup_dialog_centered(_dialog)


func set_parallel_scene(idx: int, scene_path: String) -> void:

	if not _active_previews:
		return

	_set_preview_visible(idx, false)

	var old_preview: Node = _active_previews[idx]
	_active_previews[idx] = null

	if not scene_path.is_empty():
		var scene: PackedScene = load(scene_path)
		if is_instance_valid(scene):
			var preview: Node = scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
			if is_instance_valid(preview):
				_active_previews[idx] = preview
				_set_preview_visible(idx, true)

	if is_instance_valid(old_preview):
		old_preview.free()


func clear_parallel_scene(idx: int) -> void:

	set_parallel_scene(idx, "")


func clear_all_parallel_scenes() -> void:

	for i in 4:
		clear_parallel_scene(i)


func _set_preview_visible(idx: int, visible: bool) -> void:

	if not _active_previews:
		return

	var preview := _active_previews[idx] as Node
	if not is_instance_valid(preview):
		return

	var vp := EditorInterface.get_editor_viewport_3d(idx)

	if visible:
		if not is_instance_valid(vp.world_3d):
			vp.world_3d = World3D.new()
		if not preview.get_parent():
			vp.add_child(preview)
		vp.own_world_3d = true
	else:
		var vpc: SubViewportContainer = vp.get_parent()
		vpc.remove_child(vp)
		if preview.get_parent():
			preview.get_parent().remove_child(preview)
		vp.own_world_3d = false
		vp.world_3d = null
		vpc.add_child(vp)


func _on_scene_changed(scene_root: Node) -> void:

	for i in 4:
		_set_preview_visible(i, false)

	if scene_root:

		_active_previews = _previews_by_scene.get_or_add(
				scene_root.scene_file_path,
				[null, null, null, null])

		if _previews_dirty_by_scene.get(scene_root.scene_file_path, false):
			_previews_dirty_by_scene[scene_root.scene_file_path] = false
			for i in 4:
				var preview: Node = _active_previews[i]
				if is_instance_valid(preview):
					set_parallel_scene(i, preview.scene_file_path)
		else:
			for i in 4:
				_set_preview_visible(i, true)


func _on_scene_saved(path: String) -> void:

	for i in 4:
		_set_preview_visible(i, false)

	if _active_previews:
		for i in 4:
			var old_preview: Node = _active_previews[i]
			if not is_instance_valid(old_preview):
				continue
			_active_previews[i] = null
			var preview_scn: PackedScene = load(old_preview.scene_file_path)
			if is_instance_valid(old_preview):
				old_preview.free()
			if is_instance_valid(preview_scn):
				var preview: Node = preview_scn.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
				_active_previews[i] = preview

	for scene_path in _previews_by_scene.keys():
		var previews = _previews_by_scene.get(scene_path, null)
		if previews == _active_previews:
			continue
		for i in 4:
			_set_preview_visible(i, true)
		_previews_dirty_by_scene[scene_path] = true


func _on_scene_closed(path: String) -> void:

	var previews = _previews_by_scene.get(path, null)
	if not previews:
		return
	if previews == _active_previews:
		for i in 4:
			_set_preview_visible(i, false)
		_active_previews = null

	await Engine.get_main_loop().process_frame

	if not EditorInterface.get_open_scenes().has(path):
		for preview in previews:
			if is_instance_valid(preview):
				preview.free()
		_previews_by_scene.erase(path)


func _on_dialog_file_selected(path: String) -> void:

	set_parallel_scene(_asking_idx, path)

	await Engine.get_main_loop().process_frame
	if _dialog.is_inside_tree():
		_dialog.get_parent().remove_child(_dialog)


func _on_dialog_canceled() -> void:

	await Engine.get_main_loop().process_frame
	if _dialog.is_inside_tree():
		_dialog.get_parent().remove_child(_dialog)
