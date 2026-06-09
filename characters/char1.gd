extends CharacterBody3D

@export var mouse_sensitivity := 0.003
var target_rotation_y := 0.0

const SPEED = 7
const JUMP_VELOCITY = 7
const MAX_FALL_SPEED = 25.0
const GRAVITY = 20.0

@onready var mesh = $MeshInstance3D

var last_direction = "down"
var current_anim := ""
var current_frame := 0
var timer := 0.0
var flip := false

const COLUMNS = 32
const ROWS = 4
const FRAME_W = 1.0 / COLUMNS
const FRAME_H = 1.0 / ROWS

const ANIMATIONS = {
	"idleup":   [0, 8,  4, 6.0],
	"idleright":[0, 4,  4, 6.0],
	"idledown": [0, 0,  4, 6.0],
	"idleside": [0, 4,  4, 6.0],
	"runup":    [1, 12,  6, 10.0],
	"runright": [1, 6,  6, 10.0],
	"rundown":  [1, 0, 6, 10.0],
	"runside":  [1, 6,  6, 10.0],
}

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	play_animation("idledown", false)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		target_rotation_y -= event.relative.x * mouse_sensitivity
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_jump()
	handle_movement()
	update_animation()
	advance_frame(delta)
	rotation.y = lerp_angle(rotation.y, target_rotation_y, 0.15)
	move_and_slide()

func handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("ui_accept") and velocity.y > 0:
		velocity.y *= 0.3

func apply_gravity(delta: float) -> void:
	if not is_on_floor() and velocity.y > -MAX_FALL_SPEED:
		velocity.y -= GRAVITY * delta

func handle_movement() -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func update_animation() -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir != Vector2.ZERO:
		if abs(input_dir.x) > abs(input_dir.y):
			play_animation("runside", input_dir.x < 0)
			last_direction = "left" if input_dir.x < 0 else "right"
		else:
			if input_dir.y < 0:
				play_animation("runup", false)
				last_direction = "up"
			else:
				play_animation("rundown", false)
				last_direction = "down"
	else:
		match last_direction:
			"left":  play_animation("idleside", true)
			"right": play_animation("idleside", false)
			"up":    play_animation("idleup", false)
			"down":  play_animation("idledown", false)

func play_animation(anim_name: String, flipped: bool) -> void:
	if current_anim == anim_name and flip == flipped:
		return
	current_anim = anim_name
	flip = flipped
	current_frame = 0
	timer = 0.0
	_update_uv()

func advance_frame(delta: float) -> void:
	if current_anim == "":
		return
	var data = ANIMATIONS[current_anim]
	timer += delta
	if timer >= 1.0 / data[3]:
		timer = 0.0
		current_frame = (current_frame + 1) % data[2]
		_update_uv()

func _update_uv() -> void:
	var mat = mesh.get_active_material(0) as StandardMaterial3D
	if mat == null:
		return
	var data = ANIMATIONS[current_anim]
	var col = data[1] + current_frame
	if flip:
		mat.uv1_offset = Vector3((col + 1) * FRAME_W, data[0] * FRAME_H, 0)
		mat.uv1_scale = Vector3(-FRAME_W, FRAME_H, 1)
	else:
		mat.uv1_offset = Vector3(col * FRAME_W, data[0] * FRAME_H, 0)
		mat.uv1_scale = Vector3(FRAME_W, FRAME_H, 1)
