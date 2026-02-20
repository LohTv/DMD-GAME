extends CharacterBody3D

var speed = 500.0

func _process(delta: float) -> void:
	position += transform.basis.z * -speed * delta
