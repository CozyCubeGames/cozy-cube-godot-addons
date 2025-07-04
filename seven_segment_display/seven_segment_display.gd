@tool
class_name SevenSegmentDisplay
extends MultiMeshInstance3D


enum ContentMode { NONE, INTEGER, STRING, BIT_FLAGS }

const CHAR_BIT_FLAGS := {
	"0": 0b1111110,
	"1": 0b0110000,
	"2": 0b1101101,
	"3": 0b1111001,
	"4": 0b0110011,
	"5": 0b1011011,
	"6": 0b1011111,
	"7": 0b1110000,
	"8": 0b1111111,
	"9": 0b1111011,
	"A": 0b1110111,
	"a": 0b1110111,
	"B": 0b1111111,
	"b": 0b0011111,
	"C": 0b1001110,
	"c": 0b0001101,
	"D": 0b0111101,
	"d": 0b0111101,
	"E": 0b1001111,
	"e": 0b1101111,
	"F": 0b1000111,
	"f": 0b1000111,
	"G": 0b1011110,
	"g": 0b1111011,
	"H": 0b0110111,
	"h": 0b0010111,
	"I": 0b0110000,
	"i": 0b0010000,
	"J": 0b0111100,
	"j": 0b0111100,
	"L": 0b0001110,
	"l": 0b0110000,
	"N": 0b1110110,
	"n": 0b0010101,
	"O": 0b1111110,
	"o": 0b0011101,
	"P": 0b1100111,
	"p": 0b1100111,
	"Q": 0b1110011,
	"q": 0b1110011,
	"R": 0b0000101,
	"r": 0b0000101,
	"S": 0b1011011,
	"s": 0b1011011,
	"T": 0b0001111,
	"t": 0b0001111,
	"U": 0b0111110,
	"u": 0b0011100,
	"Y": 0b0111011,
	"y": 0b0111011,
	"Z": 0b1101101,
	"z": 0b1101101,
	"-": 0b0000001,
	"_": 0b0001000,
}

@export var digit_mesh: SevenSegmentDigitMesh:
	get: return digit_mesh
	set(value):
		if digit_mesh == value:
			return
		if digit_mesh:
			digit_mesh.changed.disconnect(_on_digit_mesh_changed)
		digit_mesh = value
		if digit_mesh:
			digit_mesh.rebuild()
			digit_mesh.changed.connect(_on_digit_mesh_changed)
		if is_instance_valid(multimesh) and is_node_ready():
			if digit_mesh:
				multimesh.mesh = digit_mesh
				multimesh.instance_count = digit_count
				_refresh_digits()
			else:
				multimesh.instance_count = 0
				multimesh.mesh = null
@export_range(1, 32, 1) var digit_count: int = 1:
	get: return digit_count
	set(value):
		if digit_count == value:
			return
		digit_count = value
		if is_node_ready() and is_instance_valid(multimesh):
			if multimesh.mesh:
				multimesh.instance_count = digit_count
			_refresh_digits()
@export var content_mode: ContentMode = ContentMode.INTEGER:
	get: return content_mode
	set(value):
		if content_mode == value:
			return
		content_mode = value
		if is_node_ready():
			_refresh_digits()
		notify_property_list_changed()
@export var content_integer: int = 0:
	get: return content_integer
	set(value):
		if content_integer == value:
			return
		content_integer = value
		if is_node_ready() and content_mode == ContentMode.INTEGER:
			_refresh_digits()
@export var content_integer_padding: bool = false:
	get: return content_integer_padding
	set(value):
		if content_integer_padding == value:
			return
		content_integer_padding = value
		if is_node_ready() and content_mode == ContentMode.INTEGER:
			_refresh_digits()
@export var content_string: String = "":
	get: return content_string
	set(value):
		if content_string == value:
			return
		content_string = value
		if is_node_ready() and content_mode == ContentMode.STRING:
			_refresh_digits()
@export var content_bit_flags: PackedByteArray:
	get: return content_bit_flags
	set(value):
		if content_bit_flags == value:
			return
		content_bit_flags = value
		if is_node_ready() and content_mode == ContentMode.BIT_FLAGS:
			_refresh_digits()
@export_range(0.0, 1.0, 0.01) var spacing: float = 0.25:
	get: return spacing
	set(value):
		if spacing == value:
			return
		spacing = value
		if is_node_ready():
			_refresh_digits()
@export var horizontal_alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER:
	get: return horizontal_alignment
	set(value):
		if horizontal_alignment == value:
			return
		horizontal_alignment = value
		if is_node_ready():
			_refresh_digits()
@export var vertical_alignment: VerticalAlignment = VERTICAL_ALIGNMENT_CENTER:
	get: return vertical_alignment
	set(value):
		if vertical_alignment == value:
			return
		vertical_alignment = value
		if is_node_ready():
			_refresh_digits()


func _ready() -> void:

	if Engine.is_editor_hint():
		if not material_override:
			material_override = load("uid://bphjkhgsv5fc7")

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	if digit_mesh:
		multimesh.mesh = digit_mesh
		multimesh.instance_count = digit_count

	_refresh_digits()


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"multimesh":
			property.usage = PROPERTY_USAGE_NONE
		"content_integer", "content_integer_padding":
			if content_mode != ContentMode.INTEGER:
				property.usage = PROPERTY_USAGE_STORAGE
		"content_string":
			if content_mode != ContentMode.STRING:
				property.usage = PROPERTY_USAGE_STORAGE
		"content_bit_flags":
			if content_mode != ContentMode.BIT_FLAGS:
				property.usage = PROPERTY_USAGE_STORAGE


func _refresh_digits() -> void:

	if not is_instance_valid(multimesh):
		return
	if not is_instance_valid(digit_mesh):
		return

	var total_width := digit_mesh.size.x * (digit_count + spacing * (digit_count - 1))
	var origin := Vector3.ZERO
	match horizontal_alignment:
		HORIZONTAL_ALIGNMENT_RIGHT:
			origin.x = -total_width
		HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_FILL:
			origin.x = -total_width / 2
	match vertical_alignment:
		VERTICAL_ALIGNMENT_TOP:
			origin.y = -digit_mesh.size.y
		VERTICAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_FILL:
			origin.y = -digit_mesh.size.y / 2

	var bfs: PackedByteArray
	match content_mode:
		ContentMode.BIT_FLAGS:
			bfs = content_bit_flags
		ContentMode.STRING, ContentMode.INTEGER:
			bfs.resize(digit_count)
			var s: String
			if content_mode == ContentMode.STRING:
				s = content_string
			else:
				if content_integer_padding:
					s = ("%0" + str(digit_count) + "d") % content_integer
				else:
					s = str(content_integer)
			for i in mini(s.length(), digit_count):
				bfs[bfs.size() - 1 - i] = CHAR_BIT_FLAGS.get(s[s.length() - 1 - i], 0)

	for i in digit_count:
		var p := Vector3(
				digit_mesh.size.x * (i * (1 + spacing) + 0.5),
				digit_mesh.size.y / 2, 0)
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, origin + p))
		var bf := bfs[i] if i < bfs.size() else 0
		multimesh.set_instance_custom_data(i, _encode_digit_bit_flag(bf))


func _encode_digit_bit_flag(bf: int) -> Color:

	return Color(
		((bf >> 5) & 3) / 4.0,
		((bf >> 3) & 3) / 4.0,
		((bf >> 1) & 3) / 4.0,
		((bf << 1) & 3) / 4.0)


func _on_digit_mesh_changed() -> void:

	if is_instance_valid(multimesh):
		multimesh.mesh = digit_mesh
		_refresh_digits()
