extends Area2D

@export var speed = 400.0
@export var lifetime = 3.0
@export var damage = 25

var direction = Vector2.ZERO
var velocity = Vector2.ZERO

func _ready():
	print("=== PROJECTILE DEBUG ===")
	print("Projectile spawned at: ", global_position)
	print("Direction: ", direction)
	print("Velocity: ", velocity)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	print("Signals connected!")
	
	# Destroy projectile after lifetime
	await get_tree().create_timer(lifetime).timeout
	print("Projectile lifetime expired - destroying")
	queue_free()

func _physics_process(delta):
	# Move projectile
	position += velocity * delta
	
	# Debug position every 30 frames
	if Engine.get_physics_frames() % 30 == 0:
		print("Projectile position: ", global_position)

func initialize(start_pos, dir):
	print("=== INITIALIZE DEBUG ===")
	print("Start position: ", start_pos)
	print("Direction: ", dir)
	
	position = start_pos
	direction = dir.normalized()
	velocity = direction * speed
	
	print("Final position: ", position)
	print("Final direction: ", direction)
	print("Final velocity: ", velocity)
	
	# Rotate projectile to face direction
	rotation = direction.angle()
	print("Rotation: ", rotation)
	print("==========================")

func _on_body_entered(body):
	print("Projectile hit body: ", body.name)
	
	# Ignore the player
	if body.is_in_group("player"):
		print("Ignoring player collision")
		return
	
	# Hit enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Enemy hit! Damage: ", damage)
	
	# Destroy projectile on hit
	print("Destroying projectile")
	queue_free()

func _on_area_entered(area):
	print("Projectile hit area: ", area.name)
	
	# Ignore the player
	if area.get_parent() and area.get_parent().is_in_group("player"):
		print("Ignoring player area collision")
		return
	
	# Hit other areas (if needed)
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		print("Area hit! Damage: ", damage)
	
	# Destroy projectile on hit
	print("Destroying projectile")
	queue_free()
