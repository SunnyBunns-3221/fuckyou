extends CharacterBody2D

@export var speed = 150.0
@export var detection_range = 300.0
@export var health = 100

var player = null
var touching_player = false

func _ready():
	# Find the player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Enemy: No player found!")

func _physics_process(_delta):
	if not player:
		return
	
	# Don't move if touching player
	if touching_player:
		velocity = Vector2.ZERO
		return
	
	# Calculate distance to player
	var distance = global_position.distance_to(player.global_position)
	
	# Move towards player if in range
	if distance <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	
	# Apply movement
	move_and_slide()

func take_damage(amount):
	health -= amount
	print("Enemy took damage! Health: ", health)
	
	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	# Die if health <= 0
	if health <= 0:
		print("Enemy defeated!")
		queue_free()

func _on_area_entered(area):
	if area.get_parent().has_method("take_damage"):
		print("Enemy touched player!")
		area.get_parent().take_damage()
		touching_player = true
		velocity = Vector2.ZERO

func _on_area_exited(area):
	if area.get_parent().has_method("take_damage"):
		print("Enemy stopped touching player!")
		touching_player = false
