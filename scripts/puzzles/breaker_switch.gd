extends Interactable
## One switch on a BreakerPanel: press E to flip it UP or DOWN.

signal flipped

const CLICK := preload("res://assets/audio/repair_click.wav")

@export var number := 1

var is_up := false

var _handle: MeshInstance3D
var _label: Label3D
var _sound: AudioStreamPlayer3D


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.14, 0.3, 0.12)
	shape.shape = box
	add_child(shape)
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.14, 0.3, 0.03)
	plate.mesh = plate_mesh
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.15, 0.15, 0.14)
	plate.material_override = plate_mat
	add_child(plate)
	_handle = MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.05, 0.12, 0.05)
	_handle.mesh = handle_mesh
	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.85, 0.75, 0.2)
	_handle.material_override = handle_mat
	add_child(_handle)
	_label = Label3D.new()
	_label.pixel_size = 0.002
	_label.font_size = 32
	_label.position = Vector3(0, 0.2, 0.02)
	add_child(_label)
	_sound = AudioStreamPlayer3D.new()
	_sound.stream = CLICK
	_sound.unit_size = 4.0
	add_child(_sound)
	_update()


func set_up(value: bool) -> void:
	is_up = value
	_update()


func get_prompt(_by: Player) -> String:
	return "[E] Flip switch %d %s" % [number, "DOWN" if is_up else "UP"]


func _on_interact(_by: Player) -> void:
	_flip.rpc(not is_up)


@rpc("authority", "call_local", "reliable")
func _flip(value: bool) -> void:
	set_up(value)
	_sound.play()
	flipped.emit()


func _update() -> void:
	if _handle == null:
		return
	_handle.position = Vector3(0, 0.07 if is_up else -0.07, 0.045)
	_label.text = "%d\n%s" % [number, "UP" if is_up else "DOWN"]
