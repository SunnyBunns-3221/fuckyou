extends CharacterBody2D

@export var speed = 300.0
@export var health = 100

# Projectile system - set this in the editor
@export var projectile_scene: PackedScene
@export var fire_rate = 0.2  # Seconds between shots
var can_fire = true

func _ready():
	print("=== PLAYER DEBUG ===")
	print("Player ready!")
	print("Projectile scene: ", projectile_scene)
	print("Can fire: ", can_fire)
	print("==================")

func _physics_process(delta):
	# Movement (your existing code)
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
		print("Mouse clicked! Attempting to fire...")
		fire_projectile()

func fire_projectile():
	print("=== FIRE PROJECTILE DEBUG ===")
	print("Can fire: ", can_fire)
	print("Projectile scene: ", projectile_scene)
	
	if not projectile_scene:
		print("ERROR: No projectile scene set in editor!")
		return
	
	print("Projectile scene is valid!")
	
	# Get mouse position in world space
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	print("Mouse position: ", mouse_pos)
	print("Player position: ", global_position)
	print("Direction: ", direction)
	
	# Spawn projectile slightly away from player to avoid collision
	var spawn_offset = direction * 35  # 35 pixels away from player center
	var spawn_position = global_position + spawn_offset
	
	print("Spawn offset: ", spawn_offset)
	print("Spawn position: ", spawn_position)
	
	# Create projectile
	print("Creating projectile...")
	var projectile = projectile_scene.instantiate()
	print("Projectile created: ", projectile)
	
	print("Adding to scene...")
	get_tree().current_scene.add_child(projectile)
	print("Projectile added to scene!")
	
	# Initialize projectile at the offset position
	print("Initializing projectile...")
	projectile.initialize(spawn_position, direction)
	print("Projectile initialized!")
	
	# Fire rate cooldown
	can_fire = false
	print("Fire cooldown started...")
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
	print("Fire cooldown ended!")
	print("================================")

# Your existing functions
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
