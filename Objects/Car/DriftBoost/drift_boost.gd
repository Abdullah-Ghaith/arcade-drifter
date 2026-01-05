class_name drift_boost extends AnimatedSprite2D

const COLOR_TWEEN_DURATION = 0.15 #seconds
const COLOR_UPDATE_PERIOD = 0.1 #seconds
const SHINY_FACTOR = 1.4

@onready var bumper_marker = get_parent()
@onready var car : player_car = bumper_marker.get_parent().get_parent()

var last_boost := -1.0
var color_tween: Tween
var color_update_cooldown := 0.0


#TODO clean this up by utilizing car boost level from car, use that to align instead of comments
const BOOST_COLOR_RAMP := [
	Color.WHITE,                        # LEVEL_0
	Color(2.007, 0.355, 0.0, 1.0),   # LEVEL_1
	Color(0.665, 1.5, 2.521),        # LEVEL_2
	Color(0.343, 1.726, 1.058),      # LEVEL_3
]

const BOOST_STRETCH_RAMP := [
	0.0,                        # LEVEL_0
	3.0,                        # LEVEL_1
	4.0,                        # LEVEL_2
	5.0,                        # LEVEL_3
]


#TODO make these grabbable from the resource defined in car
@onready var BOOST_THRESHOLDS : Array[float] = car.get_drift_level_boosts()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_as_top_level(true)
	set_z_index(-1)
	SignalBus.drift_boost_end.connect(_handle_drift_boost_end)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_position = bumper_marker.global_position
	rotation = car.rotation
	var curr_boost = car.engine_boost

	### Handle Color Modulation ###
	color_update_cooldown -= delta
	if color_update_cooldown <= 0.0:
		_update_boost_color(curr_boost)
		last_boost = curr_boost
		color_update_cooldown = COLOR_UPDATE_PERIOD
	
	### Handle Stretching:
	_update_boost_stretch(curr_boost)

func _update_boost_color(boost: float):
	var target_color := _get_color_from_boost(boost)
	self.modulate = target_color * SHINY_FACTOR

	if color_tween and color_tween.is_valid():
		color_tween.kill()

	color_tween = create_tween()
	color_tween.set_trans(Tween.TRANS_QUAD)
	color_tween.set_ease(Tween.EASE_OUT)

	color_tween.tween_property(
		self,
		"modulate",
		target_color,
		COLOR_TWEEN_DURATION
	)

func _get_color_from_boost(boost: float) -> Color:
	for i in range(BOOST_THRESHOLDS.size() - 1):
		var low := BOOST_THRESHOLDS[i]
		var high := BOOST_THRESHOLDS[i + 1]

		if boost >= low and boost <= high:
			var t := inverse_lerp(low, high, boost)
			return BOOST_COLOR_RAMP[i].lerp(BOOST_COLOR_RAMP[i + 1], t)

	return BOOST_COLOR_RAMP.back()

func _update_boost_stretch(boost: float) -> void:
	var stretch_factor = _get_stretch_from_boost(boost)
	self.scale.x = stretch_factor

func _get_stretch_from_boost(boost: float) -> float:
	for i in range(BOOST_THRESHOLDS.size() - 1):
		var low := BOOST_THRESHOLDS[i]
		var high := BOOST_THRESHOLDS[i + 1]

		if boost >= low and boost <= high:
			var t := inverse_lerp(low, high, boost)
			return lerpf(BOOST_STRETCH_RAMP[i], BOOST_STRETCH_RAMP[i + 1], t)

	return BOOST_STRETCH_RAMP.back()


func _handle_drift_boost_end() -> void:
	self.queue_free()
