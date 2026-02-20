extends RigidBody3D

var player_in_drinking_area = false
var effect_active = false  # Track if effect is currently active
var original_velocity = 0.0  # Store the original value

func _ready():
	# optional: freeze rotation on X/Z so it doesn't tip over too much
	axis_lock_angular_x = false
	axis_lock_angular_z = false

func _on_player_detecter_body_entered(body: Node3D) -> void:
	if body.name == 'player':
		player_in_drinking_area = true
		print("Player entered the drinking area")

func _on_player_detecter_body_exited(body: Node3D) -> void:
	if body.name == 'player':
		player_in_drinking_area = false
	
func _physics_process(delta: float) -> void:
	if player_in_drinking_area and Input.is_action_just_pressed("ui_e"):
		if not effect_active:  # Only allow drinking if effect is not already active
			apply_speed_boost()
			visible = false  # Hides the node
			$CollisionShape3D.disabled = true  # Optional: disable collision
			print("Player pressed E inside drinking area")

func apply_speed_boost():
	var player = get_node("../player") 
	
	if player:
		# Store original jump velocity
		original_velocity = player.base_speed
		
		# Apply boost
		player.base_speed = 20.0
		effect_active = true
		
		print("Jump boost applied! Jump velocity:", player.base_speed)
		
		# Start timer to remove effect after 10 seconds
		await get_tree().create_timer(10.0).timeout
		
		# Remove boost
		remove_speed_boost(player)

func remove_speed_boost(player):
	if player and effect_active:
		player.base_speed = original_velocity
		effect_active = false
		print("Speed boost expired. Velocity restored to:", player.base_speed)
		
		# Optional: Make potion reappear after effect ends
		# visible = true
		# $CollisionShape3D.disabled = false
