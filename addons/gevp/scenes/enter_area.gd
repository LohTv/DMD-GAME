extends Area3D

var player_in_area := false
var player_ref : Node3D = null  # Will hold the player node



func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		player_ref = body   # Store reference to player
		print("Player entered the car area!")
	else:
		pass # Replace with function body.


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		player_ref = body   # Store reference to player
		print("Player exited the car area!")
	else:
		pass # Replace with function body.

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("enter_car"):
		if player_ref: 
			player_ref.enter_car()  # Call the function on the player
