class_name drift_boost extends AnimatedSprite2D

@onready var bumper_marker = get_parent()
@onready var car = bumper_marker.get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_as_top_level(true)
	set_z_index(-1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	self.global_position = bumper_marker.global_position
	self.rotation = car.rotation
