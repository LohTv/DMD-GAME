extends Node3D
## Controls any [Vehicle] node using custom-defined input maps.
class_name VehicleController

## The [Vehicle] that this vehicle controller will send
## input values to. Required for the vehicle controller to work properly.
@export var vehicle_node : Vehicle

@export_group("Input Maps", "string_")
## The name of the input map used for this vehicle's brakes input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_brake_input: String = "Brakes"
## The name of the input map used for steering this vehicle left.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_steer_left: String = "Steer Left"
## The name of the input map used for steering this vehicle right.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_steer_right: String = "Steer Right"
## The name of the input map used for this vehicle's throttle input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_throttle_input: String = "Throttle"
## The name of the input map used for this vehicle's handbrake input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_handbrake_input: String = "Handbrake"
## The name of the input map used for this vehicle's clutch input.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_clutch_input: String = "Clutch"
## The name of the input map used for enabling or disabling
## the transmission of this vehicle.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_toggle_transmission: String = "Toggle Transmission"
## The name of the input map used for shifting up a gear when
## manual transmission is enabled.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_shift_up: String = "Shift Up"
## The name of the input map used for shifting down a gear when
## manual transmission is enabled.
## [br]The input map must be present in your project, and can be set at [code]Project > Project Settings > Input Map[/code].
## [br]Leave blank to disable.
@export var string_shift_down: String = "Shift Down"

var player_inside := false
var car_zone := false

func _physics_process(_delta):	
	if not player_inside:
		entering_the_car()
		return
		
	$Camera3D.make_current()
	exiting_the_car()
	
	if string_brake_input != "":
		vehicle_node.brake_input = Input.get_action_strength(string_brake_input)

	if string_steer_left != "" and string_steer_right != "":
		vehicle_node.steering_input = Input.get_action_strength(string_steer_left) - Input.get_action_strength(string_steer_right)

	if string_throttle_input != "":
		vehicle_node.throttle_input = pow(Input.get_action_strength(string_throttle_input), 2.0)

	if string_handbrake_input != "":
		vehicle_node.handbrake_input = Input.get_action_strength(string_handbrake_input)
	
	if string_clutch_input != "":
		vehicle_node.clutch_input = clampf(Input.get_action_strength(string_clutch_input) + Input.get_action_strength(string_handbrake_input), 0.0, 1.0)
	
	if string_toggle_transmission != "":
		if Input.is_action_just_pressed(string_toggle_transmission):
			vehicle_node.automatic_transmission = not vehicle_node.automatic_transmission
	
	if string_shift_up != "":
		if Input.is_action_just_pressed(string_shift_up):
			vehicle_node.manual_shift(1)
	
	if string_shift_down != "":
		if Input.is_action_just_pressed(string_shift_down):
			vehicle_node.manual_shift(-1)
	
	# Reverse gear logic

	if vehicle_node.current_gear == -1:
		vehicle_node.brake_input = Input.get_action_strength(string_throttle_input)
		vehicle_node.throttle_input = Input.get_action_strength(string_brake_input)



func _on_player_detecer_body_entered(body: Node3D) -> void:
		if body.name == 'player':
			car_zone = true
			print("Player Detected!")
		pass # Replace with function body.


func _on_player_detecer_body_exited(body: Node3D) -> void:
		if body.name == 'player':
			car_zone = false
			print("Player Exited!")
		pass # Replace with function body.
		
func entering_the_car():
	if Input.is_action_just_pressed("ui_e") and car_zone:
		var hidden_player = get_parent().get_node("player")
		hidden_player.visible = false
		hidden_player.driving = true
		hidden_player.velocity = Vector3.ZERO
		$Camera3D.make_current()
		player_inside = true
		
func exiting_the_car():
	var vehicle = $VehicleRigidBody
	var hidden_player = get_parent().get_node("player")
	var new_location = vehicle.global_transform.origin - 2*vehicle.global_transform.basis.x
	if Input.is_action_just_pressed("ui_e") and car_zone == false:
		hidden_player.visible = true
		hidden_player.driving = false
		vehicle.speed = 0.0
		player_inside = false
		hidden_player.global_transform.origin = new_location
