extends CharacterBody3D

# Exported Variables
@export var sprint_enabled: bool = true
@export var crouch_enabled: bool = true
@export var base_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.0
@export var sensitivity: float = 0.1
@export var accel: float = 10.0
@export var crouch_speed: float = 3.0

# Member Variables
var speed: float = base_speed
var state: String = "normal"  # normal, sprinting, crouching
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_fov_extents: Array[float] = [75.0, 85.0]  # index 0 is normal, index 1 is sprinting
var base_player_y_scale: float = 1.0
var crouch_player_y_scale: float = 0.75
var target_height: float = 1.8  # Desired height in meters
var original_height: float = 1.0  # Original height in meters, assuming the default height is 1.0


# Define raycast length
const RAY_LENGTH = 2


# Define custom signals
signal book_clicked

# Node References
@onready var parts: Dictionary = {
	"head": $head,
	"camera": $head/camera,
	"camera_animation": $head/camera/camera_animation,
	"body": $body,
	"collision": $collision
}
@onready var world: SceneTree = get_tree()

func _ready() -> void:
	original_height = parts["body"].scale.y  # Store original height
	set_player_height(target_height)
	parts["camera"].current = true

func _process(delta: float) -> void:
	
	if !Global.is_in_dialogue:
	
		handle_movement_input(delta)
		update_camera(delta)

	

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	if !Global.is_in_dialogue:
		handle_jump()
		move_character(delta)

func _input(event: InputEvent) -> void:
	if !Global.is_in_dialogue:
		if event is InputEventMouseMotion:
			handle_mouse_movement(event)
		if event is InputEventMouseButton and event.is_pressed():
			check_if_looking_at_interactable()
		if event is InputEventKey and event.as_text_key_label() == "P" and event.is_pressed():
			print(event.as_text_key_label())
			print(get_parent().get_child(0).name)
			var photobook = get_parent().get_child(0)
			photobook.visible = !photobook.visible
			
	
	

# Movement Logic
func handle_movement_input(delta: float) -> void:
	if Input.is_action_pressed("move_sprint") and !Input.is_action_pressed("move_crouch") and sprint_enabled:
		if !$crouch_roof_detect.is_colliding(): #if the player is crouching and underneath a ceiling that is too low, don't let the player stand up
			enter_sprint_state(delta)
	elif Input.is_action_pressed("move_crouch") and !Input.is_action_pressed("move_sprint") and crouch_enabled:
		enter_crouch_state(delta)
	else:
		if !$crouch_roof_detect.is_colliding(): #if the player is crouching and underneath a ceiling that is too low, don't let the player stand up
			enter_normal_state(delta)

func enter_sprint_state(delta: float) -> void:
	state = "sprinting"
	speed = sprint_speed
	parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)

func enter_crouch_state(delta: float) -> void:
	state = "crouching"
	speed = crouch_speed
	apply_crouch_transform(delta)

func enter_normal_state(delta: float) -> void:
	state = "normal"
	speed = base_speed
	reset_transforms(delta)

# Camera Logic
func update_camera(delta: float) -> void:
	match state:
		"sprinting":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[1], 10 * delta)
		"normal":
			parts["camera"].fov = lerp(parts["camera"].fov, camera_fov_extents[0], 10 * delta)

# Animation Logic
func apply_crouch_transform(delta: float) -> void:
	parts["body"].scale.y = lerp(parts["body"].scale.y, crouch_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, crouch_player_y_scale, 10 * delta)

func reset_transforms(delta: float) -> void:
	parts["body"].scale.y = lerp(parts["body"].scale.y, base_player_y_scale, 10 * delta)
	parts["collision"].scale.y = lerp(parts["collision"].scale.y, base_player_y_scale, 10 * delta)

# Physics Logic
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_jump() -> void:
	if Input.is_action_pressed("move_jump") and is_on_floor():
		velocity.y += jump_velocity

func move_character(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector2 = input_dir.normalized().rotated(-parts["head"].rotation.y)
	if is_on_floor():
		velocity.x = lerp(velocity.x, direction.x * speed, accel * delta)
		velocity.z = lerp(velocity.z, direction.y * speed, accel * delta)
	move_and_slide()

# Input Handling
func handle_mouse_movement(event: InputEventMouseMotion) -> void:
	if !world.paused:
		parts["head"].rotation_degrees.y -= event.relative.x * sensitivity
		parts["head"].rotation_degrees.x -= event.relative.y * sensitivity
		parts["head"].rotation.x = clamp(parts["head"].rotation.x, deg_to_rad(-90), deg_to_rad(90))

func set_player_height(height: float) -> void:
	var scale_factor = height / original_height
	parts["body"].scale.y *= scale_factor
	parts["collision"].scale.y *= scale_factor

var times_checked = 0

func check_if_looking_at_interactable():
	
	
	
	print("checking for npc " + str(times_checked))
	
	times_checked = times_checked + 1
	
	
	var space_state = get_world_3d().direct_space_state
	var cam = $head/camera
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)

	#print(result)

	if result:

		print("got result" )

		var collider = result["collider"]
		print("found collider: " + collider.name)
		
		if collider.is_in_group("npcs"):
			handle_looking_at_npc(collider)
		elif collider.get_name() == "PolaroidBody":
			handle_looking_at_polaroid(collider)


func handle_looking_at_npc(collider):

	print("collider is an npc")
	var npc = collider
	# Open dialogue tree with this NPC
	var dialogue_filepath = "res://dialogue/" + collider.name + ".dialogue"
	var dialogue_file = load(dialogue_filepath)
	
	var baloon_filepath = "res://dialogue/balloon.tscn"
	var baloon_file = load(baloon_filepath)
	
	if dialogue_file:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		DialogueManager.show_dialogue_balloon_scene(baloon_file, dialogue_file)

func handle_looking_at_polaroid(collider):
	print("body:" + collider.name)
	print("mesh:" + collider.get_parent().name)
	print("name:" + collider.get_parent().get_parent().name)
	

	
	
	var number = collider.get_parent().get_parent().name.substr(8)
	
	#only works specifically for the word "polaroid"
	print("number:" + number)
	
	# send signal to book
	emit_signal("book_clicked", number)
	
	collider.get_parent().get_parent().queue_free()
	

