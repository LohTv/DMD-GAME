extends RigidBody3D

var speed = 1000.0

func _ready():
	# Apply initial velocity when bullet spawns
	linear_velocity = -transform.basis.z * speed
	
	await get_tree().create_timer(5.0).timeout
	queue_free()
