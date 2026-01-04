extends CharacterBody2D

const DRIFT_TRANSITION_TIME_S = 0.6
const DEAD_VELOCITY = 50
const STEER_COYOTE_TIME = 0.25
const ENGINE_BOOST_DECAY = 5

@onready var car_sprite: Sprite2D = $CarSprite
@onready var car_shadow: Sprite2D = $CarSprite/CarShadow
@onready var drift_handler: Node2D = $DriftHandler


#TODO make all of these into a resource file
@export var wheel_base = 30
@export var steering_angle = 15.0
@export var base_steering_angle = 15.0
@export var drift_steering_angle = 40.0
@export var base_engine_power = 1160/3
@export var friction = -55
@export var drift_friction = -75
@export var drag = -0.06
@export var braking = -450
@export var max_speed_reverse = 250
@export var slip_speed = 400
@export var traction_fast = 2.5
@export var traction_slow = 10
@export var drift_traction = 0.3
@export var drift_level_boosts = {
	Consts.DriftLevel.LEVEL_0 : 0,
	Consts.DriftLevel.LEVEL_1 : 300,
	Consts.DriftLevel.LEVEL_2 : 600,
	Consts.DriftLevel.LEVEL_3 : 1160,
}

var heading: Vector2
var acceleration : Vector2 = Vector2.ZERO
var engine_boost : float = 0.0
var steer_direction: float
var drift_tween: Tween = null
var drift_state: Consts.DriftState = Consts.DriftState.NEUTRAL
var steer_coyote_timer = 0.0
var steering_active = false
var engine_power


func _ready() -> void:
	drift_handler.drift_boost.connect(_handle_drift_boost)

func _physics_process(delta):
	acceleration = Vector2.ZERO
	get_input(delta)
	apply_friction(delta)
	apply_boost(delta)
	calculate_steering(delta)
	velocity += acceleration * delta
	car_sprite.global_position = global_position
	move_and_slide()
	
func apply_friction(delta):
	if acceleration == Vector2.ZERO and velocity.length() < DEAD_VELOCITY:
		velocity = Vector2.ZERO
	var friction_force
	if Input.is_action_pressed("drift"):
		friction_force = velocity * drift_friction * delta
	else:
		friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force
	
func get_input(delta):
	# TURNING INPUT
	var turn = Input.get_axis("steer_left", "steer_right")
	steer_direction = turn * deg_to_rad(base_steering_angle)
	var turning = (turn != 0)

	### STEER COYOTE TIME ###
	if turning:
		steer_coyote_timer = STEER_COYOTE_TIME
	else:
		steer_coyote_timer = max(steer_coyote_timer - delta, 0.0)
	steering_active = steer_coyote_timer

	### DRIFT STATE MACHINE ###
	var prev_drift_state = drift_state
	if Input.is_action_pressed("drift") and steering_active:
		drift_state = Consts.DriftState.DRIFTING
	elif Input.is_action_just_released("drift") or not steering_active:
		drift_state = Consts.DriftState.NEUTRAL
	if drift_state != prev_drift_state:
		SignalBus.drift_state_changed.emit(drift_state)

	### GAS/BRAKE INPUT
	if Input.is_action_pressed("accelerate"):
		acceleration = transform.x * engine_power
	if Input.is_action_pressed("brake"):
		acceleration = transform.x * braking
	
func calculate_steering(delta):
	var rear_wheel = position - transform.x * wheel_base / 2.0
	var front_wheel = position + transform.x * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(steer_direction) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)
	heading = new_heading
	var traction = traction_slow
	if drift_state == Consts.DriftState.DRIFTING:
		traction = drift_traction
		drift_tween  = create_tween()
		drift_tween.tween_property(self, "base_steering_angle", drift_steering_angle, DRIFT_TRANSITION_TIME_S).set_ease(Tween.EASE_OUT)
	else:
		base_steering_angle = steering_angle
		traction = traction_slow
		if velocity.length() > slip_speed:
			traction = traction_fast
	var d = new_heading.dot(velocity.normalized())
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction * delta)
	elif Input.is_action_pressed("brake") and d < 0:
		velocity = lerp(velocity, (-new_heading * min(velocity.length(), max_speed_reverse)), traction*delta)
	rotation = new_heading.angle()

func apply_boost(delta) -> void:
	engine_power = base_engine_power + engine_boost
	engine_boost = max(engine_boost-ENGINE_BOOST_DECAY, 0.0)
	print(engine_power)

func _handle_drift_boost(drift_level: Consts.DriftLevel) -> void:
	engine_boost += drift_level_boosts[drift_level]
	engine_power += engine_boost
	#TODO while engine boost, emit car boost fumes particle 
