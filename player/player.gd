extends CharacterBody2D

@export var speed = 300.0
@export var health = 10000
@export var runspeed = 500.0

# Projectile system
@export var projectile_scene: PackedScene
@export var fire_rate = 0.2
@export var shoot_radius = 35.0

var can_fire = true

# Animation system
@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
var facing_direction = Vector2.RIGHT
var is_moving = false
var current_animation = "idle"

# Screen boundaries
var screen_width = 1920
var screen_height = 1080

@onready var healthbar = $Healthbar

@export var gravity = 600.0
@export var jump_velocity = -600.0
var vertical_velocity = 0.0
var is_jumping = false
var jump_start_y = 0.0

func _ready():
	healthbar.value = health
	
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")
	
	# Start with idle animation
	play_animation("idle")

func _physics_process(delta):
	# Handle jump input
	if (Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_W)) and not is_jumping:
		if is_on_floor():
			is_jumping = true
			jump_start_y = global_position.y
			vertical_velocity = jump_velocity
	
	# Apply gravity to vertical velocity
	vertical_velocity += gravity * delta
	
	# Apply vertical movement (direct position)
	global_position.y += vertical_velocity * delta
	
	# Reset jump when back on ground
	if is_jumping and global_position.y >= jump_start_y:
		is_jumping = false
		vertical_velocity = 0.0
		global_position.y = jump_start_y
	
	# Handle horizontal movement
	var direction = 0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direction += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direction -= 1
	
	# Apply horizontal movement (direct position)
	if direction != 0:
		global_position.x += direction * speed * delta
	
	# Move the character (for collision detection)
	move_and_slide()
	
	# Keep player within screen bounds
	keep_in_bounds()
	
	# Shooting
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_fire:
		fire_projectile()

func play_animation(anim_name):
	if not animation_player or current_animation == anim_name:
		return
	
	current_animation = anim_name
	
	# Handle sprite flipping for left/right
	if anim_name == "walk_left" or anim_name == "slide_left":
		sprite.flip_h = true
	elif anim_name == "walk_right" or anim_name == "slide_right":
		sprite.flip_h = false
	
	# Play the animation
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		print("Animation not found: ", anim_name)

func keep_in_bounds():
	# Calculate player bounds for 64x128 sprite
	var player_width = 64
	var player_height = 128
	var half_width = player_width / 2
	var half_height = player_height / 2
	
	# Keep within screen boundaries
	if global_position.x < half_width:
		global_position.x = half_width
	elif global_position.x > screen_width - half_width:
		global_position.x = screen_width - half_width
	
	if global_position.y < half_height:
		global_position.y = half_height
	elif global_position.y > screen_height - half_height:
		global_position.y = screen_height - half_height

func fire_projectile():
	if not projectile_scene:
		return
	
	# Get mouse position in world space
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Calculate spawn position on the circle boundary
	var spawn_position = global_position + (direction * shoot_radius)
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Initialize projectile with shooter reference
	projectile.initialize(spawn_position, direction, self)
	
	# Fire rate cooldown
	can_fire = false
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true

func take_damage(amount = 10):
	health -= amount
	healthbar.value = health
	print("Player took damage! Health: ", health)
	modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE
	if health <= 0:
		print("Game Over!")
		get_tree().paused = true	

func teleport_to_door(new_position):
	position = new_position
	modulate.a = 0.5
	await get_tree().create_timer(0.1).timeout
	modulate.a = 1.0
