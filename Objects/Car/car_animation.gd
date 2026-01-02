extends Node2D

@onready var player : CharacterBody2D = get_owner()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%AnimationTree.active = true
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	%AnimationTree.set("parameters/blend_position", player.heading.normalized())
