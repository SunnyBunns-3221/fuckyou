extends CharacterBody2D

@export var speed = 300.0
@export var health = 100
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

# Bobbing system
var bob_amount = 4.0  # How many pixels to bob up/down
var bob_speed = 20.0   # How fast the bob happens
var original_y = 0.0  # Store original Y position
var bob_timer = 0.0   # Timer for bobbing

# Screen boundaries
var screen_width = 1920
var screen_height = 1080

#Dash mechanic
@export var dashspeed = 900.0
@export var dashduration = 0.2
@export var dashcooldown = 5.0
var isdashing = false
var dashtimer = 0.0
var dashcooldowntimer = 0.0
@onready var dashbar = $DashBar
@export var dashrechargedelay = 1
var dashdelaytimer = 0.0


func _ready():
	# Store original Y position for bobbing
	original_y = sprite.position.y
	
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")
	
	# Start with idle animation
	play_animation("idle")

func _physics_process(delta):
	# Movement
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	var current_speed = speed
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = runspeed
	
	
	if direction.length() > 0:
		direction = direction.normalized()
		is_moving = true
		
		# Update bobbing timer
		bob_timer += delta * bob_speed
		
		# Update facing direction for animation
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				facing_direction = Vector2.RIGHT
				play_animation("walk_right")
			else:
				facing_direction = Vector2.LEFT
				play_animation("walk_left")
		else:
			if direction.y > 0:
				facing_direction = Vector2.DOWN
				play_animation("walk_right")
			else:
				facing_direction = Vector2.UP
				play_animation("walk_left")
	else:
		is_moving = false
		bob_timer = 0.0  # Reset bob timer when stopped
		
		# Return to idle animation
		if current_animation != "idle":
			play_animation("idle")
	
	# Apply bobbing effect
	apply_bob_effect()
	
	if dashtimer > 0.0:
		dashtimer -= delta
		if dashtimer <= 0.0:
			isdashing = false
			dashdelaytimer = dashrechargedelay
	if dashcooldowntimer > 0.0:
		dashcooldowntimer -= delta
		dashbar.value = dashcooldown - dashcooldowntimer
	else:
		dashbar.value = dashcooldown
	
	if Input.is_key_pressed(KEY_SPACE) and not isdashing and dashcooldowntimer <= 0.0 and direction.length() > 0:
		isdashing = true
		dashtimer = dashduration
		dashcooldowntimer = dashcooldown
	if isdashing:
		current_speed =  dashspeed
	velocity = direction * current_speed
	if dashdelaytimer > 0.0:
		dashdelaytimer -= delta
	elif dashcooldowntimer > 0.0:
		dashcooldowntimer -= delta
	else:
		dashbar.value = dashcooldown
	
	move_and_slide()
	
	# Keep player within screen bounds
	keep_in_bounds()
	
	# Shooting
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_fire:
		fire_projectile()

func apply_bob_effect():
	if is_moving:
		# Create smooth up/down bobbing motion
		var bob_offset = sin(bob_timer) * bob_amount
		sprite.position.y = original_y + bob_offset
	else:
		# Return to original position when not moving
		sprite.position.y = original_y

func play_animation(anim_name):
	if not animation_player or current_animation == anim_name:
		return
	
	current_animation = anim_name
	
	# Handle sprite flipping for left/right
	if anim_name == "walk_left":
		sprite.flip_h = true
	elif anim_name == "walk_right":
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
	print("Player took damage! Health: ", health)
	modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE
	if health <= 0:
		print("Game Over!")

func teleport_to_door(new_position):
	position = new_position
	modulate.a = 0.5
	await get_tree().create_timer(0.1).timeout
	modulate.a = 1.0
