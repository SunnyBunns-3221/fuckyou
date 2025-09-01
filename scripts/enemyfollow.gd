extends CharacterBody2D

@export var speed: float = 50.0
@export var stop_time: float = 0.5  
@onready var player: Node2D = get_parent().get_node("player")

var stop_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not player:
		return

	
	if stop_timer > 0.0:
		stop_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed

	
	var collision = move_and_collide(velocity * delta)
	if collision and collision.get_collider() == player:
		velocity = Vector2.ZERO
		stop_timer = stop_time 
	else:
		move_and_slide()
