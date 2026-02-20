# ProtoController v1.0 by Brackeys
# CC0 License
# Modified by ChatGPT (GPT-5) to include 3D looping footstep sound.
# Works with a long walking sound file that loops.
# Enhanced with proper inventory system

extends CharacterBody3D

## --- MOVEMENT SETTINGS ---
@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
@export var look_speed : float = 0.005
@export var base_speed : float = 7.0
@export var jump_velocity : float = 4.5
@export var sprint_speed : float = 10.0
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"
@export var input_forward : String = "ui_up"
@export var input_back : String = "ui_down"
@export var input_jump : String = "ui_accept"
@export var input_sprint : String = "sprint"
@export var input_freefly : String = "freefly"
@export var input_throw : String = "throw_item"
@export var input_cycle_next : String = "cycle_inventory_next"
@export var input_cycle_prev : String = "cycle_inventory_prev"

## --- INTERNALS ---
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

## --- NODE REFERENCES ---
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

## --- FOOTSTEP SOUND ---
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
var was_moving: bool = false
var fade_tween: Tween = null
## -----------------------

## --- CAR ENTRY ---
var driving: bool = false

## --- HEALTH ---
var health: float = 100.0

## --- FALL DAMAGE SETTINGS ---
var fall_safe_speed := 8.0      # falling slower than this = no damage
var fall_damage_scale := 2.0    # damage multiplier
var was_in_air := false
var highest_fall_speed := 0.0

## ---- BULLET ----
var bullet = load("res://addons/gevp/scenes/bullet_2_0.tscn")
@onready var pos = $Head/Camera3D/Gun/Pos

## ---- SHOOT FLASH ----
@onready var shot_flash: Node3D = $Head/Camera3D/ShotFlash  # Adjust path to match your scene
var flash_duration := 0.05  # How long the flash stays visible (in seconds)

## ---- RECOIL ----
var recoil_current := Vector2.ZERO
var recoil_target := Vector2.ZERO

@export var recoil_up := 1.0
@export var recoil_side := 0.5
@export var recoil_kick_speed := 50.0
@export var recoil_return_speed := 18.0


### ---- KICKBACK ----
@export var recoil_push_strength := 1.6
@export var recoil_push_upward := 0.2

## ---- INVENTORY ----
var inventory := []               # List of items the player has
var current_item_index := -1      # Which item is currently equipped (-1 = none)
var held_item: RigidBody3D = null # Reference to the currently held item

@export var max_inventory_size := 5

## ---- PICKUP ----
@onready var pickup_area: Area3D = $PickUpArea

var nearby_pickups: Array[RigidBody3D] = []



func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func apply_fall_damage(amount: float):
	health -= amount
	health = round(health)
	print("FALL DAMAGE: ", amount, "  Health now: ", health)
	if health <= 0:
		die()
	
func die():
	print("Player died.")
	# TODO: respawn / reload / ragdoll / etc.
	
func apply_recoil():
	recoil_target.x += recoil_up
	recoil_target.y += randf_range(-recoil_side, recoil_side)
	
func show_muzzle_flash():
	if shot_flash == null:
		return
	
	# Make flash visible
	shot_flash.visible = true
	
	# Hide after short delay
	await get_tree().create_timer(flash_duration).timeout
	shot_flash.visible = false
	
# checking for gun
func is_holding_gun() -> bool:
	# Check if the held item is a gun by checking if it's in the "gun" group
	if held_item != null and held_item.is_in_group("gun"):
		return true
	return false

## --- INVENTORY MANAGEMENT ---

func pickup_item():
	if nearby_pickups.is_empty():
		return

	if inventory.size() >= max_inventory_size:
		print("Inventory full (", max_inventory_size, " items max)")
		return

	var item: RigidBody3D = nearby_pickups[0]

	# Disable physics
	item.freeze = true
	item.collision_layer = 0
	item.collision_mask = 0

	# Add to inventory
	inventory.append(item)
	
	# If nothing is currently held, equip this item
	if held_item == null:
		current_item_index = inventory.size() - 1
		equip_item(current_item_index)
	else:
		# Store it invisibly
		item.reparent(self)
		item.visible = false
		item.position = Vector3.ZERO

	print("Picked up: ", item.name, " | Inventory: ", inventory.size(), "/", max_inventory_size)

func equip_item(index: int):
	# Unequip current item if any
	if held_item != null:
		held_item.visible = false
		held_item.reparent(self)
		held_item.position = Vector3.ZERO
	
	# Equip new item
	if index >= 0 and index < inventory.size():
		current_item_index = index
		held_item = inventory[index]
		
		held_item.reparent(head)
		held_item.position = Vector3(0.3, -0.3, -0.6)
		held_item.rotation = Vector3.ZERO
		held_item.visible = true
		
		print("Equipped: ", held_item.name, " [", index + 1, "/", inventory.size(), "]")
	else:
		current_item_index = -1
		held_item = null

func cycle_inventory_next():
	if inventory.is_empty():
		return
	
	var next_index = (current_item_index + 1) % inventory.size()
	equip_item(next_index)

func cycle_inventory_prev():
	if inventory.is_empty():
		return
	
	var prev_index = (current_item_index - 1 + inventory.size()) % inventory.size()
	equip_item(prev_index)

func throw_item():
	if held_item == null:
		print("No item to throw")
		return
	
	var item = held_item
	
	# Remove from inventory
	inventory.erase(item)
	
	# Unequip
	held_item = null
	current_item_index = -1
	
	# Restore physics and throw
	item.reparent(get_parent())
	item.visible = true
	item.freeze = false
	item.collision_layer = 2
	item.collision_mask = 2
	
	var dir = -head.global_transform.basis.z
	item.global_position = head.global_position + dir
	item.linear_velocity = dir * 12 + Vector3.UP * 2
	
	print("Threw: ", item.name, " | Inventory: ", inventory.size(), "/", max_inventory_size)
	
	# Equip next item if available
	if not inventory.is_empty():
		current_item_index = 0
		equip_item(0)
	
	# Re-add to nearby pickups if still in range
	if pickup_area.overlaps_body(item):
		if item not in nearby_pickups:
			nearby_pickups.append(item)

## --- END INVENTORY MANAGEMENT ---
		
func _physics_process(delta: float) -> void:
	
	# ---------------- RECOIL SYSTEM ----------------

	# Smooth kick toward recoil target
	recoil_current = recoil_current.lerp(recoil_target, recoil_kick_speed * delta)

	# Smooth return back to zero
	recoil_target = recoil_target.lerp(Vector2.ZERO, recoil_return_speed * delta)

	# Apply recoil to camera rotation
	look_rotation += recoil_current * delta

	# Clamp vertical look AFTER recoil applied
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))

	# Update camera transforms
	transform.basis = Basis()
	rotate_y(look_rotation.y)

	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)
		
	if driving:
		pass
	
	if not driving:
		$Head/Camera3D.make_current()
		
	# Freefly mode
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Gravity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta
			
	if not is_on_floor():
		was_in_air = true
	# Track the MOST negative velocity (highest downward speed)
	if velocity.y < highest_fall_speed:
		highest_fall_speed = velocity.y
	# Jump
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Movement
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_toward(velocity.x, move_dir.x * move_speed, move_speed * 6 * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * move_speed, move_speed * 6 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	move_and_slide()
	
	if was_in_air and is_on_floor():
		var impact_speed = abs(highest_fall_speed)

		if impact_speed > fall_safe_speed:
			var damage = (impact_speed - fall_safe_speed) * fall_damage_scale
			apply_fall_damage(damage)

	# Reset tracking
	was_in_air = false
	highest_fall_speed = 0.0

	# --- FOOTSTEP SOUND HANDLING ---
	if is_on_floor() and can_move:
		var moving = abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1

		if moving and not was_moving:
			start_footsteps()
		elif not moving and was_moving:
			stop_footsteps()

		was_moving = moving
	else:
		if was_moving:
			stop_footsteps()
		was_moving = false
		
	# ---- SHOOTING ----
	if Input.is_action_just_pressed("click") and not driving:
		if is_holding_gun():
			apply_recoil()
			show_muzzle_flash()
		
			var instance = bullet.instantiate()
			instance.position = pos.global_position
			instance.transform.basis = pos.global_transform.basis
			get_parent().add_child(instance)
		else:
			return
		
	# ---- INVENTORY CONTROLS ----
	
	# Pickup item (right-click)
	if Input.is_action_just_pressed("right_click") and not driving:
		pickup_item()
	
	# Throw current item (Q key)
	if Input.is_action_just_pressed(input_throw) and not driving:
		throw_item()
	
	# Cycle inventory next
	if Input.is_action_just_pressed(input_cycle_next) and not driving:
		cycle_inventory_next()
	
	# Cycle inventory previous
	if Input.is_action_just_pressed(input_cycle_prev) and not driving:
		cycle_inventory_prev()

func start_footsteps():
	if not footstep_player.playing:
		if fade_tween: fade_tween.kill()
		footstep_player.volume_db = -10 # start slightly low
		footstep_player.play()
		fade_tween = create_tween()
		fade_tween.tween_property(footstep_player, "volume_db", 0, 0.2) # fade in quickly

func stop_footsteps():
	if footstep_player.playing:
		if fade_tween: fade_tween.kill()
		fade_tween = create_tween()
		fade_tween.tween_property(footstep_player, "volume_db", -30, 0.3) # fade out
		fade_tween.tween_callback(Callable(footstep_player, "stop"))
		fade_tween.tween_property(footstep_player, "volume_db", 0, 0) # reset instantly
		
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func _on_pick_up_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("pickup"):
		nearby_pickups.append(body)
		print("Nearby item: ", body.name, " | Total nearby: ", nearby_pickups.size())

func _on_pick_up_area_body_exited(body: Node3D) -> void:
	if body in nearby_pickups:
		nearby_pickups.erase(body)
