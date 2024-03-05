extends CharacterBody3D

var speed

# speed consts
const WALK_SPEED = 5.0
const SPRINT_SPEED = 10.0
const CROUCHING_SPEED = 2.5

var IS_SPRINTING = false
var IS_CROUCHING = false

# player height
const DEFAULT_HEIGHT = 1.5
const CROUCH_HEIGHT = 0.5

# speed of the transition between walking and crouching
const CROUCH_TRANSITION_SPEED = 15

var JUMP_VELOCITY

const JUMP_VELOCITY_WALK = 4.8
const JUMP_VELOCITY_SPRINT = 6.8
const JUMP_VELOCITY_CROUCH = 2.8

const SENSITIVITY = 0.004

# bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

# fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var player_collision = $CollisionShape3D

@onready var head_position = head.position

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


# to do : passer sprint en "hold" avec une jauge
func sprint():
	if Input.is_action_just_pressed("sprint") and is_on_floor():
		IS_SPRINTING = not IS_SPRINTING
		IS_CROUCHING = false
	
	if IS_SPRINTING:
		speed = SPRINT_SPEED

# to do : is sprinting = slide, !is_on_floor : ground pound https://www.youtube.com/watch?v=dublNJgr13M
func crouch(delta):
	if Input.is_action_just_pressed("crouch") and is_on_floor() and not IS_SPRINTING:
		IS_CROUCHING = not IS_CROUCHING
		
	if Input.is_action_just_pressed("crouch") and is_on_floor() and IS_SPRINTING:
		IS_CROUCHING = not IS_CROUCHING
		IS_SPRINTING = not IS_SPRINTING
		
		
	if IS_CROUCHING:
		speed = CROUCHING_SPEED
		JUMP_VELOCITY = JUMP_VELOCITY_CROUCH
		player_collision.shape.height -= CROUCH_TRANSITION_SPEED * delta
	else:
		player_collision.shape.height += CROUCH_TRANSITION_SPEED * delta

	player_collision.shape.height = clamp(player_collision.shape.height, CROUCH_HEIGHT, DEFAULT_HEIGHT)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP /2
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP /2
	return pos


func _physics_process(delta):

	speed = WALK_SPEED
	JUMP_VELOCITY = JUMP_VELOCITY_WALK

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	sprint()
	crouch(delta)
	jump()
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
