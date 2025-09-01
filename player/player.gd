extends CharacterBody2D

@export var speed = 300.0

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_D): direction.x += 1
	if Input.is_key_pressed(KEY_A): direction.x -= 1
	if Input.is_key_pressed(KEY_S): direction.y += 1
	if Input.is_key_pressed(KEY_W): direction.y -= 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
