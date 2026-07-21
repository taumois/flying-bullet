extends Node

const LASER_SLIME = preload("res://scenes/laser_slime.tscn")
const ROCKET_SLIME = preload("res://scenes/rocket_slime.tscn")
const MAX_SLIMES = 6
const DISTANCE_TO_SPAWN_FROM_BULLET = 4000.0

var bullet

func _ready() -> void:
	bullet = get_node("../Bullet")


func _physics_process(delta: float) -> void:
	var new_slime = LASER_SLIME.instantiate() if randf() > 0.5 else ROCKET_SLIME.instantiate()
	var offset_vector = Vector2.from_angle(randf() * PI) * DISTANCE_TO_SPAWN_FROM_BULLET
	new_slime.position = bullet.position + offset_vector
	add_child(new_slime)
