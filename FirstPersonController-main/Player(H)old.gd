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

const JUMP_VELOCITY = 4.8

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


func jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Preserve horizontal velocity when jumping
		
		
		var horizontal_velocity = Vector3(velocity)
		horizontal_velocity.y = JUMP_VELOCITY
		velocity = horizontal_velocity
		


func sprint(): 
	if Input.is_action_pressed("sprint") and is_on_floor():
		IS_SPRINTING = true
		speed = SPRINT_SPEED
	else:
		IS_SPRINTING = false;

func crouch(delta):
	if Input.is_action_pressed("crouch") and is_on_floor() and !IS_SPRINTING:
		IS_CROUCHING = true
		speed = CROUCHING_SPEED
		player_collision.shape.height -= CROUCH_TRANSITION_SPEED * delta
	else:
		player_collision.shape.height += CROUCH_TRANSITION_SPEED * delta
		IS_CROUCHING = false;
		
	# Clamp the crouch height
	player_collision.shape.height = clamp(player_collision.shape.height, CROUCH_HEIGHT, DEFAULT_HEIGHT)


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _physics_process(delta):
	
	if is_on_floor:
		# Reset player speed.
		speed = WALK_SPEED
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_on_floor:
	# Handle Jump.	
		jump(delta)
	
	# Handle Crouching.
		crouch(delta)

	# Handle Sprint.
		sprint()

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	#else:
		#velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		#velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()
