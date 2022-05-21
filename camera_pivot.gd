extends Spatial

var direction = Vector3.FORWARD

func _physics_process(delta):
	var current_velocity = get_parent().get_linear_velocity()
	direction = lerp(direction, -current_velocity.normalized(), 2.5 * delta)
