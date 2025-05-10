@tool
class_name ParallelSceneViewButton
extends MenuButton


const CLEAR_ITEM_ID: int = 999


func _ready() -> void:

	if self == EditorInterface.get_edited_scene_root():
		return

	icon = EditorInterface.get_editor_theme().get_icon("PackedScene", "EditorIcons")
	get_popup().id_pressed.connect(_on_id_pressed)


func _on_id_pressed(id: int) -> void:

	var plugin := ParallelSceneViewPlugin.instance
	if not plugin:
		return

	if id >= CLEAR_ITEM_ID:
		plugin.clear_all_parallel_scenes()
		return

	if plugin.has_parallel_scene(id):
		plugin.clear_parallel_scene(id)
	else:
		plugin.ask_for_parallel_scene(id)


func _on_about_to_popup() -> void:

	if self == EditorInterface.get_edited_scene_root():
		return

	var plugin := ParallelSceneViewPlugin.instance
	if not plugin:
		return

	get_popup().clear()

	if not EditorInterface.get_edited_scene_root():
		get_popup().add_item("No open scenes.")
		get_popup().set_item_disabled(0, true)
		return

	get_popup().add_separator("Parallel Scene Views", 100)

	var num: int = 1
	var has_any_parallel_scene: bool
	for i in 4:
		var vp := EditorInterface.get_editor_viewport_3d(i)
		var vpc: SubViewportContainer = vp.get_parent()
		if not vpc.is_visible_in_tree():
			continue
		var label := str(num) + ". "
		var has_parallel_scene := plugin.has_parallel_scene(i)
		if has_parallel_scene:
			has_any_parallel_scene = true
			label += plugin.get_parallel_scene(i)
		else:
			label += "[None]"
		get_popup().add_check_item(label, i)
		get_popup().set_item_checked(get_popup().item_count - 1, has_parallel_scene)
		num += 1

	get_popup().add_separator()

	get_popup().add_item("Clear All", CLEAR_ITEM_ID)
	get_popup().set_item_disabled(get_popup().item_count - 1, not has_any_parallel_scene)
