extends CharacterBody2D

@export var speed = 150.0
@export var detection_range = 300.0
@export var separation_distance = 40.0  # Distance to maintain from player

var player = null
var touching_player = false

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# If we're too close to player, move away
	if distance < separation_distance:
		var direction_away = (global_position - player.global_position).normalized()
		velocity = direction_away * speed * 0.5  # Move away slower
		touching_player = true
		print("Too close - moving away from player")
	# If we're in detection range but not too close, move towards
	elif distance <= detection_range and not touching_player:
		var direction_towards = (player.global_position - global_position).normalized()
		velocity = direction_towards * speed
		print("Following player - distance: ", distance)
	else:
		velocity = Vector2.ZERO
		touching_player = false
	
	move_and_slide()

func _on_area_entered(area):
	if area.get_parent().has_method("take_damage"):
		print("Enemy touched player!")
		area.get_parent().take_damage()
		touching_player = true
		# Immediately move away
		var direction_away = (global_position - player.global_position).normalized()
		velocity = direction_away * speed

func _on_area_exited(area):
	if area.get_parent().has_method("take_damage"):
		print("Enemy stopped touching player!")
		touching_player = false
