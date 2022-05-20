extends RigidBody

export(float) var ride_height = 2.0
export(float) var ride_spring_strength = 30
export(float) var ride_spring_damper = 3
export(float) var righting_spring_strength = 20
export(float) var righting_spring_damper = 2

export(float) var max_speed = 20
export(float) var strafe_speed = 30
export(float) var brake_force = 20

export(float) var lean_angle = 10

export(float) var jump_force = 12
export(float) var coyote = 0.2
export(float) var bunnyhop_time = 0.2

var grounded: bool = false
var do_float: bool = true
var jumping = false

var left:bool = false
var right:bool = false
var brake:bool = false
var time_since_grounded = 0
var grounded_time = 0

onready var time_since_jump = coyote

onready var ground_ray:RayCast = $RayCast 

func get_floating():
	return do_float

func _process(delta):
	if ground_ray.is_colliding():
		$DropShadow.global_transform.origin = ground_ray.get_collision_point()
		$DropShadow.visible = true
	else:
		$DropShadow.visible = false
	process_input(delta)
		
func process_input(delta):
	left = left or Input.is_action_just_pressed("left")
	right = right or Input.is_action_just_pressed("right")
	brake = brake or Input.is_action_just_pressed("brake")
	if Input.is_action_just_pressed("jump"):
		time_since_jump = 0;
	else:
		time_since_jump += delta
	if grounded:
		grounded_time += delta
		time_since_grounded = 0
	else:
		grounded_time = 0
		time_since_grounded += delta

func _physics_process(delta):
	if(global_transform.origin.z < -39):
		global_transform.origin.z = -1
	
func _integrate_forces(state):
	ground_ray.cast_to = Vector3.DOWN*ride_height*2
	ground_ray.force_raycast_update()
	var ray_dir_vel = state.linear_velocity.dot(Vector3.UP)
	var hit_point = ground_ray.get_collision_point()
	var ride_offset = transform.origin.y - to_local(hit_point).y
	var diff = ride_height-abs(ride_offset)
	grounded = diff >= 0 and ground_ray.is_colliding()
	do_float = !jumping and ground_ray.is_colliding() and diff >= -ride_height*0.5
	if do_float:
		#floating
		var spring_force = (diff * ride_spring_strength) - (ray_dir_vel * ride_spring_damper)
		add_central_force(Vector3.UP * spring_force)
	
	if(state.linear_velocity.length() < max_speed):
		add_central_force(Vector3.FORWARD * max_speed)
	
	#movement
	if left:
		left = false
		state.linear_velocity.x = 0
		apply_central_impulse(Vector3.LEFT * strafe_speed)
	if right:
		right = false
		state.linear_velocity.x = 0
		apply_central_impulse(Vector3.RIGHT * strafe_speed)
	if brake:
		brake = false
		state.linear_velocity.z
	
	var lean_axis: Vector3 = Vector3.FORWARD
	var cur_rot:Vector3 = global_transform.basis.y
	var targ_rot:Vector3
	if state.linear_velocity.x == 0:
		targ_rot = ground_ray.get_collision_normal()
	else:
		targ_rot = ground_ray.get_collision_normal()#Quat(lean_axis.normalized(), deg2rad(lean_angle) * (state.linear_velocity.length()/max_speed)).normalized() * ground_ray.get_collision_normal()
	
	var angle:float = cur_rot.angle_to(targ_rot)
	var rotAxis: Vector3 = cur_rot.cross(targ_rot).normalized()
	var angular_vel: Vector3 = state.angular_velocity 
	add_torque((rotAxis * (angle * righting_spring_strength)) - (angular_vel * righting_spring_damper))
	var cur_face = global_transform.basis.get_euler().y
	var move_angle = global_transform.basis.z.signed_angle_to(Vector3.FORWARD,Vector3.UP) + PI
	add_torque(global_transform.basis.y * (clamp(angle_to_angle(cur_face,move_angle),-1,1) * righting_spring_strength) - (angular_vel * righting_spring_damper))

static func angle_to_angle(from, to):
	return fposmod(to-from + PI, PI*2) - PI

