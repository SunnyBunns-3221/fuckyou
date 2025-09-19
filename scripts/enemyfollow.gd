extends CharacterBody2D

@export var speed = 150.0
@export var detection_range = 300.0
@export var health = 100
@export var fire_rate = 1.0
@export var projectile_scene: PackedScene
@export var shoot_radius = 50.0
@onready var health_bar = $ProgressBar
@export var gravity = 800.0 
enum State { PATROL, CHASE }

var player = null
var current_state = State.PATROL
var touching_player = false
var can_fire = true
var last_known_player_pos = Vector2.ZERO
var patrol_points = [
	Vector2(194, 1020),
	Vector2(454, 1020),
]
var patrol_index = 0
var patrol_direction = 1

func _ready():
	player = get_tree().get_first_node_in_group("player")
	health_bar.value = health
	
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")

func _physics_process(delta):
	if not player:
		return
	
	# Apply gravity for platformer physics
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Don't move if touching player
	if touching_player:
		velocity.x = 0  # Only stop horizontal movement, keep gravity
		move_and_slide()
		return
	
	# Simple distance-based detection
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= detection_range:
		current_state = State.CHASE
		chase_and_shoot()
	else:
		current_state = State.PATROL
		patrol_behavior()
	
	move_and_slide()

func chase_and_shoot():
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		# Only apply horizontal movement, preserve vertical velocity (gravity)
		velocity.x = direction.x * speed
		
		# Shoot at player if we can
		if can_fire and distance > 0:
			fire_at_player()

func fire_at_player():
	if not projectile_scene or not player:
		return
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
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


func take_damage(amount):
	health -= amount
	print("Enemy took damage! Health: ", health)
	health_bar.value = health
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if health <= 0:
		print("Enemy defeated!")
		queue_free()

func _on_area_entered(area):
	if area.get_parent().has_method("take_damage"):
		touching_player = true
		velocity.x = 0  # Only stop horizontal movement, keep gravity

func _on_area_exited(area):
	if area.get_parent().has_method("take_damage"):
		touching_player = false

func _on_area_2d_body_entered(body):
	if body.has_method("take_damage"):
		touching_player = true
		velocity.x = 0  # Only stop horizontal movement, keep gravity

func _on_area_2d_body_exited(body):
	if body.has_method("take_damage"):
		touching_player = false


func patrol_behavior():
	# Simple back and forth patrol
	var target_point = patrol_points[patrol_index]
	var distance_to_target = global_position.distance_to(target_point)
	
	# If close to target, switch to next patrol point
	if distance_to_target < 50:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		target_point = patrol_points[patrol_index]
	
	# Move towards current patrol point
	var direction = (target_point - global_position).normalized()
	# Only apply horizontal movement, preserve vertical velocity (gravity)
	velocity.x = direction.x * speed
