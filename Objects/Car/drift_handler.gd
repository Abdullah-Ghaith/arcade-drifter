extends Node2D

# Minimum velocity required to build drift boost, can't build by sitting still
const MINIMUM_DRIFT_BUILD_VEL = 100.0

@onready var left_wheel: Marker2D = $"../BackLeftWheel"
@onready var right_wheel: Marker2D = $"../BackRightWheel"
@onready var wheels : Array[Marker2D] = [left_wheel, right_wheel]
@onready var skid_mark_scene : PackedScene = preload("res://Objects/Car/Skidmark/skid_mark.tscn")
@onready var player : CharacterBody2D = get_parent()

var drift_state : Consts.DriftState = Consts.DriftState.NEUTRAL
var curr_drift_time : float = 0.0
var curr_drift_level: Consts.DriftLevel = Consts.DriftLevel.LEVEL_0

var driftlevel_times = { # Seconds
	Consts.DriftLevel.LEVEL_0 : {"lower_bound" : 0.0, "upper_bound" : 1.0},
	Consts.DriftLevel.LEVEL_1 : {"lower_bound" : 1.0, "upper_bound" : 2.0},
	Consts.DriftLevel.LEVEL_2 : {"lower_bound" : 2.0, "upper_bound" : 3.5},
	Consts.DriftLevel.LEVEL_3 : {"lower_bound" : 3.5, "upper_bound" : INF}	
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.drift_state_changed.connect(_handle_drift_state_changed)

func _physics_process(delta: float) -> void:
	if drift_state == Consts.DriftState.DRIFTING:

		### DRIFT BOOST HANDLING ###
		if player.velocity.length() >= MINIMUM_DRIFT_BUILD_VEL:
			curr_drift_time += delta
		curr_drift_level = determine_drift_level(curr_drift_time)
		for wheel in wheels:
			var wheel_children := wheel.get_children()
			for child in wheel_children:
				if child is Skid:
					child.drift_level = curr_drift_level

func determine_drift_level(drift_time: float) -> Consts.DriftLevel:
	for drift_lvl in Consts.DriftLevel.values():
		if drift_time > driftlevel_times[drift_lvl]["lower_bound"] and drift_time < driftlevel_times[drift_lvl]["upper_bound"]:
			return drift_lvl
	return Consts.DriftLevel.LEVEL_0

func _handle_drift_state_changed(new_drift_state: Consts.DriftState) -> void:
	if drift_state == Consts.DriftState.NEUTRAL and new_drift_state == Consts.DriftState.DRIFTING:
		### Spawn in skid marks ###
		for wheel in wheels:
			var wheel_skid = skid_mark_scene.instantiate()
			wheel.add_child(wheel_skid)
	elif drift_state == Consts.DriftState.DRIFTING and new_drift_state == Consts.DriftState.NEUTRAL:
		### Handle Drift Boost ###
		print(curr_drift_time)
		print(curr_drift_level)
		curr_drift_time = 0.0

		### Despawn skid marks ###
		for wheel in wheels:
			var wheel_children = wheel.get_children()
			for child in wheel_children:
				if child is Skid:
					child.deactivate()

	drift_state = new_drift_state
