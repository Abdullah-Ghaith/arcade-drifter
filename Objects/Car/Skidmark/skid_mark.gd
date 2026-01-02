class_name Skid extends Line2D

@onready var flame_particles: GPUParticles2D = $GPUParticles2D

const MAX_SKID_POINTS = 100


#TODO add a : set to a var here that sets the particles to different colors

var active: bool = true
var drift_level: Consts.DriftLevel = Consts.DriftLevel.LEVEL_0:
	set(value):
		set_drift_level(value)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_as_top_level(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if active:
		self.add_point(get_parent().global_position)
		if self.points.size() > MAX_SKID_POINTS:
			self.remove_point(0)
		flame_particles.global_position = get_parent().global_position
		flame_particles.emitting = true
	else:
		self.remove_point(0)
		if self.points.is_empty():
			self.queue_free()
		flame_particles.emitting = false

func deactivate() -> void:
	active = false

func set_drift_level(value: Consts.DriftLevel) -> void:
	pass
