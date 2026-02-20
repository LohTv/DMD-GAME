extends RigidBody3D

var player_in_drinking_area = false

func _ready():
	# optional: freeze rotation on X/Z so it doesn't tip over too much
	axis_lock_angular_x = false
	axis_lock_angular_z = false


func _on_player_detecter_body_entered(body: Node3D) -> void:
	if body.name == 'player':
		player_in_drinking_area = true
		print("Player entered the drinking area")
	pass # Replace with function body.


func _on_player_detecter_body_exited(body: Node3D) -> void:
	if body.name == 'player':
		player_in_drinking_area = false
		#print("Player exited the drinking area")
	pass # Replace with function body.
	
func _physics_process(delta: float) -> void:
	if player_in_drinking_area and Input.is_action_just_pressed("ui_e"):
		increase_player_health()
		visible = false  # Hides the node
		$CollisionShape3D.disabled = true  # Optional: disable collision so player can walk through
		print("Player pressed E inside drinking area")

func increase_player_health():
	var player = get_node("../player") 
	var health = player.health # adjust path to your player node
	if player:
		print("player drunk")
		player.health = min(100, player.health + 20)
		print("Player health is now:", player.health)
