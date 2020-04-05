extends RigidBody


func _physics_process(dt: float):
	add_force(-transform.basis.z * 10.0, Vector3.ZERO)
