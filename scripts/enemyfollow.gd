extends CharacterBody2D

@export var speed = 150.0
@export var detection_range = 300.0
@export var health = 100
@export var fire_rate = 1.0
@export var projectile_scene: PackedScene
@export var shoot_radius = 25.0
@onready var health_bar = $ProgressBar
@onready var nav_agent = $NavigationAgent2D
@export var gravity = 800.0 
enum State { PATROL, CHASE, RETURN, WAIT }

var player = null
var current_state = State.PATROL
var touching_player = false
var can_fire = true
var vision_cone = null
var waiting_to_return = false
var last_known_player_pos = Vector2.ZERO
var patrol_points = [
	Vector2(194, 1020),
	Vector2(454, 1020),
]
var patrol_index = 0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	vision_cone = $VisionCone
	health_bar.value = health
	
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")
	
	# Start patrol
	start_patrol()

func _physics_process(delta):
	if not player:
		return
	
	# Update vision direction based on movement
	if velocity.length() > 0:
		vision_cone.update_vision_direction(velocity)
	if not player:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
	
	# Don't move if touching player
	if touching_player:
		velocity = Vector2.ZERO
		return
	
	# Check if we can see the player
	if vision_cone.can_see_target(player.global_position):
		last_known_player_pos = player.global_position
		current_state = State.CHASE
		chase_and_shoot()
	else:
		# If we can't see player and we were chasing
		if current_state == State.CHASE:
			if not waiting_to_return:
				waiting_to_return = true
				current_state = State.WAIT
				start_return_delay()
	
	# Handle different states
	match current_state:
		State.PATROL:
			patrol_behavior()
		State.RETURN:
			return_to_patrol()
		State.WAIT:
			velocity = Vector2.ZERO
		State.CHASE:
			# Chase behavior is handled above
			pass
	
	move_and_slide()

func chase_and_shoot():
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		# Shoot at player if we can
		if can_fire and distance > 50:
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

func on_player_spotted():
	print("Enemy spotted player!")
	current_state = State.CHASE

func on_player_lost():
	print("Enemy lost sight of player!")
	if not waiting_to_return:
		waiting_to_return = true
		current_state = State.WAIT
		start_return_delay()

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
		velocity = Vector2.ZERO

func _on_area_exited(area):
	if area.get_parent().has_method("take_damage"):
		touching_player = false

func test_wall_detection():
	if not player:
		return
	
	print("=== ENEMY WALL TEST ===")
	print("Enemy position: ", global_position)
	print("Player position: ", player.global_position)
	
	# Test direct raycast to player
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.collision_mask = 4  # Walls only
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Wall detected between enemy and player!")
		print("Wall position: ", result.position)
		print("Wall collider: ", result.collider.name)
	else:
		print("No wall detected between enemy and player")
	print("========================")

func start_patrol():
	nav_agent.set_target_position(patrol_points[patrol_index])

func patrol_behavior():
	if nav_agent.is_navigation_finished():
		patrol_index = (patrol_index + 1) % patrol_points.size()
		nav_agent.set_target_position(patrol_points[patrol_index])
	
	var next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed

func return_to_patrol():
	var closest_point = patrol_points[0]
	var min_dist = global_position.distance_to(closest_point)
	
	for point in patrol_points:
		var dist = global_position.distance_to(point)
		if dist < min_dist:
			min_dist = dist
			closest_point = point
	
	nav_agent.set_target_position(closest_point)
	
	var next_pos = nav_agent.get_next_path_position()
	velocity = (next_pos - global_position).normalized() * speed
	
	if nav_agent.is_navigation_finished():
		current_state = State.PATROL
		patrol_index = patrol_points.find(closest_point)
		nav_agent.set_target_position(patrol_points[patrol_index])

func start_return_delay():
	velocity = Vector2.ZERO  # Stop movement
	await get_tree().create_timer(2.0).timeout
	last_known_player_pos = Vector2.ZERO
	current_state = State.RETURN
	waiting_to_return = false
