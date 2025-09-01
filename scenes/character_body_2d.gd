extends CharacterBody2D

@onready var player = get_node("../Player")  # Player is a Node2D
var speed = 100.0

func _physics_process(_delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
