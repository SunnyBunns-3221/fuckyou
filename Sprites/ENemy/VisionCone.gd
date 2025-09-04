extends Area2D

@export var vision_angle = 60.0
@export var vision_range = 2000.0
@export var vision_color = Color(1, 1, 0, 0.3)

var enemy = null
var player = null
var can_see_player = false
var vision_direction = Vector2.RIGHT

func _ready():
	enemy = get_parent()
	player = get_tree().get_first_node_in_group("player")
	
	# Ensure we're at the center of the enemy
	position = Vector2.ZERO
	
	# Create visual representation
	create_vision_cone_visual()
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func create_vision_cone_visual():
	# Remove old vision line if it exists
	var old_line = get_node_or_null("VisionLine")
	if old_line:
		old_line.queue_free()
	
	var line = Line2D.new()
	line.name = "VisionLine"
	line.width = 2
	line.default_color = vision_color
	
	var points = []
	var angle_rad = deg_to_rad(vision_angle / 2)
	
	# Center point (enemy center)
	points.append(Vector2.ZERO)
	
	# Left edge of cone
	var left_angle = -angle_rad
	points.append(Vector2(cos(left_angle) * vision_range, sin(left_angle) * vision_range))
	
	# Right edge of cone
	var right_angle = angle_rad
	points.append(Vector2(cos(right_angle) * vision_range, sin(right_angle) * vision_range))
	
	# Back to center
	points.append(Vector2.ZERO)
	
	line.points = points
	add_child(line)

func update_vision_direction(new_direction):
	vision_direction = new_direction.normalized()
	rotation = vision_direction.angle()

func can_see_target(target_pos):
	if not enemy or not player:
		return false
	
	var to_target = target_pos - enemy.global_position
	var distance = to_target.length()
	
	if distance > vision_range:
		#print("Target too far: ", distance, " > ", vision_range)
		return false
	
	var angle_to_target = vision_direction.angle_to(to_target)
	var angle_diff = abs(rad_to_deg(angle_to_target))
	
	if angle_diff > vision_angle / 2:
		#print("Target outside vision angle: ", angle_diff, " > ", vision_angle / 2)
		return false
	
	# Check if there's a wall blocking the view
	var wall_blocking = is_blocked_by_wall(enemy.global_position, target_pos)
	#print("Wall blocking vision: ", wall_blocking)
	return !wall_blocking

func is_blocked_by_wall(from_pos, to_pos):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 4  # Layer 4 = walls
	
	#print("=== WALL DETECTION DEBUG ===")
	#print("From position: ", from_pos)
	#print("To position: ", to_pos)
	#print("Collision mask: ", query.collision_mask)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		#print("Wall hit at: ", result.position)
		#print("Wall collider: ", result.collider.name)
		#print("Wall collider layer: ", result.collider.collision_layer)
		
		var distance_to_wall = from_pos.distance_to(result.position)
		var distance_to_target = from_pos.distance_to(to_pos)
		
		#print("Distance to wall: ", distance_to_wall)
		#print("Distance to target: ", distance_to_target)
		
		# If wall is closer than target, vision is blocked
		var blocking = distance_to_wall < distance_to_target
		#print("Wall blocking vision: ", blocking)
		#print("================================")
		return blocking
	else:
		#print("No wall detected")
		#print("================================")
		return false

func _on_area_entered(area):
	if area.get_parent() and area.get_parent().is_in_group("player"):
		can_see_player = true
		if enemy.has_method("on_player_spotted"):
			enemy.on_player_spotted()

func _on_area_exited(area):
	if area.get_parent() and area.get_parent().is_in_group("player"):
		can_see_player = false
		if enemy.has_method("on_player_lost"):
			enemy.on_player_lost()
