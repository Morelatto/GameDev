extends KinematicBody

onready var anim = get_node("AnimationPlayer")
onready var cam = get_node("Camera")
onready var skel = get_node("Armature/Skeleton")
onready var crouch_tween = get_node("CrouchTween")
onready var raycol = get_node("RayCol")
onready var footcast = get_node("FootCast")

var headbone
var initial_head_transform

var current_gun

# blend for smooth transitions between animations
const DEFAULT_BLEND = 0.1

var speed = 16
var accel = 15
var vel = Vector3()

var sens = 0.2

var grav = -60
var max_grav = -150

var jump_force = 20

var jumping = false
var crouching = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	headbone = skel.find_bone("Head")
	#cam.translation = skel.get_bone_global_pose(headbone).origin
	initial_head_transform = skel.get_bone_custom_pose(headbone)

	equip("res://Guns/lightning gun.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var movement = event.relative
		cam.rotation.x += -deg2rad(movement.y * sens)
		cam.rotation.x = clamp(cam.rotation.x, deg2rad(-90), deg2rad(90))
		rotation.y += -deg2rad(movement.x * sens)

func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if Input.is_action_just_pressed("shoot"):
		if current_gun and weakref(current_gun):
			current_gun.fire()

	if Input.is_action_just_pressed("switch_cam"):
		if cam.current:
			cam.current = false
			get_parent().get_node("Camera").current = true
		else:
			cam.current = true
			get_parent().get_node("Camera").current = false

	var target_dir = Vector2.ZERO
	if Input.is_action_pressed("forward"):
		target_dir.y += 1
	if Input.is_action_pressed("backward"):
		target_dir.y -= 1
	if Input.is_action_pressed("left"):
		target_dir.x += 1
	if Input.is_action_pressed("right"):
		target_dir.x -= 1

	if not (jumping or crouching):
		set_anim(target_dir)

	# rotate with mouse
	target_dir = target_dir.normalized().rotated(-rotation.y)

	vel.x = lerp(vel.x, target_dir.x * speed, accel * delta)
	vel.z = lerp(vel.z, target_dir.y * speed, accel * delta)

	vel.y += grav * delta
	if vel.y < max_grav:
		vel.y = max_grav

	if Input.is_action_pressed("jump") and footcast.is_colliding():
		vel.y = jump_force
		anim.play("Idle", DEFAULT_BLEND)
		anim.play("Jump", DEFAULT_BLEND)
		jumping = true

	if Input.is_action_pressed("crouch") and not (crouching or jumping):
		anim.play("Crouch", DEFAULT_BLEND)
		crouch_tween.interpolate_property(raycol.shape, "length", raycol.shape.length, 3.5, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouch_tween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0, 2.1, 0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouch_tween.start()
		crouching = true
	elif (not Input.is_action_pressed("crouch") or jumping) and crouching:
		crouch_tween.interpolate_property(raycol.shape, "length", raycol.shape.length, 5, 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouch_tween.interpolate_property(footcast, "translation", footcast.translation, Vector3(0, 0.6, 0), 0.08, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		crouch_tween.start()
		crouching = false

	move_and_slide(vel, Vector3.UP)

	if is_on_floor() and vel.y < 0:
		vel.y = 0
		jumping = false

	var current_head_transform = initial_head_transform.rotated(Vector3.LEFT, cam.rotation.x)
	skel.set_bone_custom_pose(headbone, current_head_transform)

func equip(path):
	if current_gun and weakref(current_gun):
		current_gun.queue_free()
	current_gun = null
	current_gun = load(path).instance()
	cam.add_child(current_gun)
	current_gun.translation = cam.get_node("GunPos").translation

func set_anim(dir):
	# checking for current animation so blending isn't applied incorrectly
	if dir == Vector2.ZERO and anim.current_animation != "Idle":
		anim.play("Idle", DEFAULT_BLEND)
	# checking for playing speed because the same animation is used for backwards
	elif dir == Vector2.DOWN and not (anim.current_animation == "Forward" and anim.get_playing_speed() > 0):
		anim.play("Forward", DEFAULT_BLEND)
	elif dir == Vector2(1, 1) and not (anim.current_animation == "FrontLeft" and anim.get_playing_speed() > 0):
		anim.play("FrontLeft", DEFAULT_BLEND)
	elif dir == Vector2(-1, 1) and not (anim.current_animation == "FrontRight" and anim.get_playing_speed() > 0):
		anim.play("FrontRight", DEFAULT_BLEND)
	elif dir == Vector2.RIGHT and anim.current_animation != "Left":
		anim.play("Left", DEFAULT_BLEND)
	elif dir == Vector2.LEFT and anim.current_animation != "Right":
		anim.play("Right", DEFAULT_BLEND)
	elif dir == Vector2.UP and not (anim.current_animation == "Forward" and anim.get_playing_speed() < 0):
		anim.play_backwards("Forward", DEFAULT_BLEND)
	elif dir == Vector2(1, -1) and not (anim.current_animation == "FrontRight" and anim.get_playing_speed() < 0):
		anim.play_backwards("FrontRight", DEFAULT_BLEND)
	elif dir == Vector2(-1, -1) and not (anim.current_animation == "FrontLeft" and anim.get_playing_speed() < 0):
		anim.play_backwards("FrontLeft", DEFAULT_BLEND)

