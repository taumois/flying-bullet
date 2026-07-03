# The player character, script controls physics/movement, lives, and score
extends CharacterBody2D

signal current_score(score: int)
signal current_health(health: int)
signal current_speed(speed: float)

const DAMAGE_EXPLOSION = preload("res://scenes/death_explosion.tscn")
const COLLISION_DAMAGE_TO_ENEMIES = 1
const SCORE_GAIN_FROM_DEALING_DAMAGE = 499
const INITIAL_SPEED = 35.0
const INITIAL_HEALTH = 5
const LINEAR_ACCELERATION = 0.085
const LINEAR_DRAG_COEFFICIENT = 0.0001
const ROTATIONAL_ACCELERATION = 0.0035
const ROTATIONAL_DRAG_COEFFICIENT = 0.6
const SCORE_GAIN_ON_BOUNCE = 5
const FPS_DEVELOPED_IN = 60
const BOUNCED_LINEAR_VELOCITY_COEFFICIENT = 1.5
const DRAG_EXPONENT = 2.0
const COLLISION_LIMIT = 1

var collision_limit_timer: Timer
var health
var score
var turn_direction
var linear_velocity
var rotational_velocity
var collision_count

# Represents a direction; neutral means no direction
enum Direction {
	LEFT = -1, 
	RIGHT = 1,
	NEUTRAL = 0,
}

# Sets up the player character for the game to start
func _ready() -> void:
	collision_count = 0
	collision_limit_timer = %ResetCollisionLimit
	position = Vector2.ZERO
	rotation = 0.0
	turn_direction = Direction.NEUTRAL
	linear_velocity = Vector2.ONE * INITIAL_SPEED
	rotational_velocity = 0.0
	health = INITIAL_HEALTH
	score = 0

# Uses user input to record the direction the player is going, in turn_direction, for later use
func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_pressed("turn_right"):
		turn_direction = Direction.RIGHT
	elif Input.is_action_pressed("turn_left"):
		turn_direction = Direction.LEFT
	else:
		turn_direction = Direction.NEUTRAL
	get_viewport().set_input_as_handled()

# handles movement/physics, including using turn_direction, applying drag, and calling bouce() on collisions
# is 'special_physics_process' and not '_physics_process', because I wanted more control over when in a frame this was called
# because I was wondering if it was responsible for a bug. It was not but it stuck
# (this function is called in World)
func special_physics_process(delta: float) -> void:
	var special_delta = delta * FPS_DEVELOPED_IN
	
	var speed = linear_velocity.length() * special_delta
	emit_signal("current_speed", speed)
	
	if turn_direction != null:
		rotational_velocity += turn_direction * ROTATIONAL_ACCELERATION * special_delta
	var rotational_drag = rotational_velocity * rotational_velocity * ROTATIONAL_DRAG_COEFFICIENT
	if rotational_velocity > 0.0:
		rotational_drag *= -1
	rotational_velocity += rotational_drag * special_delta
	rotation += rotational_velocity * special_delta
	
	linear_velocity = Vector2.from_angle(rotation) * speed
	linear_velocity += Vector2.from_angle(rotation) * LINEAR_ACCELERATION * special_delta
	var linear_drag = speed * speed * LINEAR_DRAG_COEFFICIENT * -1
	linear_velocity += Vector2.from_angle(rotation) * linear_drag * special_delta
	
	var collision = move_and_collide(linear_velocity)
	if collision != null:
		bounce(collision)

# Cause the player to take a specified amount of damage
# also handles the players dying/health being < 0
func damage(amount: int) -> void:
	health -= amount
	if health < 0:
		health = 0
	emit_signal("current_health", health)
	do_explosion()

# Create a cool explosion at the player's position
func do_explosion() -> void:
	var explosion = DAMAGE_EXPLOSION.instantiate()
	explosion.position = position
	add_sibling(explosion)


# Bounce the player off the object from the passed in collision, also does other stuff like
# scores score, deals damage to enemies, and increases the player speed
func bounce(collision: KinematicCollision2D) -> void:
	%BounceSound.volume_linear = randf_range(0.33, 1.66)
	%BounceSound.play(0.74)
	var collision_normal = collision.get_normal()
	var collision_collider_rid = collision.get_collider_rid()
	var pre_bounce_linear_velocity = linear_velocity
	
	var collision_collider = collision.get_collider()
	if collision_collider.has_method("damage"):
		collision_collider.damage(COLLISION_DAMAGE_TO_ENEMIES);
		if collision_collider.has_method("explode"):
			collision_collider.explode(self);
		else:
			score += SCORE_GAIN_FROM_DEALING_DAMAGE
	
	linear_velocity = linear_velocity.bounce(collision_normal) * BOUNCED_LINEAR_VELOCITY_COEFFICIENT
	rotation = linear_velocity.angle()
	
	position = collision.get_position() + pre_bounce_linear_velocity
	var stuck = true
	while(stuck):
		position += Vector2.from_angle(rotation)
		var stuck_collision = move_and_collide(Vector2.ZERO, true)
		if stuck_collision == null:
			position += Vector2.from_angle(rotation)
			stuck = false
		elif stuck_collision.get_collider_rid() != collision_collider_rid:
			bounce(stuck_collision)
			stuck = false
	
	score += SCORE_GAIN_ON_BOUNCE
	emit_signal("current_score", score)
