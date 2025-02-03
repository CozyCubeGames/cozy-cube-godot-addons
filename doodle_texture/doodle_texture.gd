@tool
class_name DoodleTexture
extends PortableCompressedTexture2D


@export var foreground_color: Color = Color.BLACK
@export var background_color: Color = Color.WHITE
@export_range(1.0, 50.0, 0.999) var brush_size: int = 8
@export var size: Vector2i = Vector2(256, 256):
	get: return size
	set(value):
		if size == value:
			return
		value.x = maxi(value.x, 1)
		value.y = maxi(value.y, 1)
		size = value
		if Engine.is_editor_hint():
			_rebuild()


func _init() -> void:

	if Engine.is_editor_hint():
		_rebuild()


func clear() -> void:

	var image := get_image()
	image.fill(background_color)
	_push_image(image)


func draw_line(p1: Vector2, p2: Vector2, background: bool = false) -> void:

	var color := background_color if background else foreground_color
	var image := get_image()
	var v := p2 - p1
	var length := v.length()
	var dir := v / length
	var sqr_radius := (brush_size * brush_size * 0.25)
	for x in size.x:
		for y in size.y:
			var p := Vector2(x + 0.5, y + 0.5)
			var closest_p: Vector2
			if is_zero_approx(length):
				closest_p = p1
			else:
				var dot := (p - p1).dot(dir)
				closest_p = p1 + dir * clampf(dot, 0, length)
			if p.distance_squared_to(closest_p) <= sqr_radius:
				image.set_pixel(x, y, color)
	_push_image(image)


func swap_colors() -> void:

	var bc := background_color
	background_color = foreground_color
	foreground_color = bc


func _rebuild() -> void:

	var image := get_image()

	if is_instance_valid(image):
		var old_size := image.get_size()
		if old_size != size:
			var old_image := image
			image = Image.create_empty(size.x, size.y, true, Image.Format.FORMAT_RGBA8)
			image.fill(background_color)
			for x in mini(size.x, old_size.x):
				for y in mini(size.y, old_size.y):
					image.set_pixel(x, y, old_image.get_pixel(x, y))
	else:
		image = Image.create_empty(size.x, size.y, true, Image.Format.FORMAT_RGBA8)
		image.fill(background_color)

	_push_image(image)


func _push_image(image: Image) -> void:

	image.generate_mipmaps()
	create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	emit_changed()


func set_data(width: int, height: int, bytes: PackedByteArray) -> void:

	_push_image(Image.create_from_data(width, height, true, Image.FORMAT_RGBA8, bytes))
