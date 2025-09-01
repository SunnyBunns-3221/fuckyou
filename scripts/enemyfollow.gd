extends CharacterBody2D

@export var speed: float = 50.0
@export var stop_time: float = 0.5
@export var stop_distance: float = 20.0
@onready var player: Node2D = get_parent().get_node("Player")

var stop_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not player:
		return

	if stop_timer > 0.0:
		stop_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	if distance > stop_distance:
		var direction = to_player.normalized()
		velocity = direction * speed

		var collision = move_and_collide(velocity * delta)
		if collision and collision.get_collider() == player:
			velocity = Vector2.ZERO
			stop_timer = stop_time
	else:
		velocity = Vector2.ZERO

	move_and_slide()
