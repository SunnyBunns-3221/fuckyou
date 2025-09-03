extends CharacterBody2D

@export var speed = 300.0
@export var health = 100

# Projectile system
@export var projectile_scene: PackedScene
@export var fire_rate = 0.1
@export var shoot_radius = 25.0
var can_fire = true

func _ready():
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")

func _physics_process(delta):
	# Movement
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Shooting
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_fire:
		fire_projectile()

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
