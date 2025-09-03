extends CharacterBody2D

@export var speed = 150.0
@export var detection_range = 300.0
@export var health = 100
@export var fire_rate = 1.0
@export var projectile_scene: PackedScene
@export var shoot_radius = 25.0  # Distance from center to spawn projectiles

var player = null
var touching_player = false
var can_fire = true
var vision_cone = null
var last_known_player_pos = Vector2.ZERO

func _ready():
	player = get_tree().get_first_node_in_group("player")
	vision_cone = $VisionCone
	
	# Load projectile scene
	if not projectile_scene:
		projectile_scene = preload("res://Projectile.tscn")

func _physics_process(delta):
	if not player:
		return
	
	# Update vision direction based on movement
	if velocity.length() > 0:
		vision_cone.update_vision_direction(velocity)
	
	# Don't move if touching player
	if touching_player:
		velocity = Vector2.ZERO
		return
	
	# Check if we can see the player
	if vision_cone.can_see_target(player.global_position):
		last_known_player_pos = player.global_position
		chase_and_shoot()
	else:
		# If we can't see player, move to last known position
		if last_known_player_pos != Vector2.ZERO:
			var distance_to_last_pos = global_position.distance_to(last_known_player_pos)
			if distance_to_last_pos > 10:
				var direction = (last_known_player_pos - global_position).normalized()
				velocity = direction * speed * 0.5
			else:
				velocity = Vector2.ZERO
				last_known_player_pos = Vector2.ZERO
		else:
			velocity = Vector2.ZERO
	
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

func on_player_lost():
	print("Enemy lost sight of player!")

func take_damage(amount):
	health -= amount
	print("Enemy took damage! Health: ", health)
	
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
