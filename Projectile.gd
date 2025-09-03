extends Area2D

@export var speed = 400.0
@export var lifetime = 3.0
@export var damage = 25

var direction = Vector2.ZERO
var velocity = Vector2.ZERO
var shooter = null

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Destroy projectile after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move projectile
	position += velocity * delta

func initialize(start_pos, dir, shooter_ref = null):
	position = start_pos
	direction = dir.normalized()
	velocity = direction * speed
	shooter = shooter_ref
	
	# Rotate projectile to face direction
	rotation = direction.angle()

func _on_body_entered(body):
	# Ignore the shooter (don't damage them)
	if body == shooter:
		return
	
	# Hit enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Enemy hit! Damage: ", damage)
	
	# Hit wall or other obstacles
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile()
	
	# Destroy projectile on hit
	queue_free()

func _on_area_entered(area):
	# Ignore the shooter
	if area.get_parent() == shooter:
		return
	
	# Hit other areas (if needed)
	if area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
		print("Area hit! Damage: ", damage)
	
	# Destroy projectile on hit
	queue_free()
