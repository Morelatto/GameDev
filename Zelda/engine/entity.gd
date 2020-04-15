class_name entity

extends KinematicBody2D

var MAXHEALTH = 1
var TYPE = "ENEMY"
var SPEED = 0
var DAMAGE = 1

var health = MAXHEALTH
var hitstun = 0

var movedir = dir.center
var knockdir = dir.center
var spritedir = "down"

var texture_default = null
var texture_hurt = null

func _ready():
	if TYPE == "ENEMY":
		set_collision_mask_bit(1, 1)
		set_physics_process(false)
	texture_default = $Sprite.texture
	texture_hurt = load($Sprite.texture.get_path().replace(".png", "_hurt.png"))

func movement_loop():
	var motion
	if hitstun == 0:
		motion = movedir.normalized() * SPEED
	else:
		motion = knockdir.normalized() * 125
	move_and_slide(motion, dir.center)

func spritedir_loop():
	match movedir:
		dir.left: spritedir = "left"
		dir.right: spritedir = "right"
		dir.up: spritedir = "up"
		dir.down: spritedir = "down"

func anim_switch(animation):
	var newanim = str(animation, spritedir)
	if $anim.current_animation != newanim:
		$anim.play(newanim)

func damage_loop():
	health = min(MAXHEALTH, health)
	if hitstun > 0:
		hitstun -= 1
		$Sprite.texture = texture_hurt
	else:
		$Sprite.texture = texture_default
		if TYPE == "ENEMY" and health <= 0:
			var drop = randi() % 3
			if drop == 0:
				instance_scene(preload("res://pickups/heart.tscn"))
			instance_scene(preload("res://enemies/enemy_death.tscn"))
			queue_free()
	# check for areas instead of bodies (item is a node)
	for area in $hitbox.get_overlapping_areas():
		var body = area.get_parent()
		if hitstun == 0 and body.get("DAMAGE") != null and body.get("TYPE") != TYPE:
			health -= body.get("DAMAGE")
			hitstun = 10
			# global because item is relative to the player
			knockdir = global_transform.origin - body.global_transform.origin

func use_item(item):
	var newitem = item.instance()
	var newitem_name = str(newitem.get_name(), self)
	newitem.add_to_group(newitem_name)
	add_child(newitem)
	# checks if theres already an existing item out
	if get_tree().get_nodes_in_group(newitem_name).size() > newitem.maxamount:
		newitem.queue_free()

func instance_scene(scene):
	var new_scene = scene.instance()
	# set its position to the entity
	new_scene.global_position = global_position
	get_parent().add_child(new_scene) # main node





