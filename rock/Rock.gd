extends RigidBody2D

var screensize : Vector2 = Vector2.ZERO
var size
var radius
var scale_factor = 0.2

var sprite : Sprite2D
var collision_shape : CollisionShape2D
var explosion_effect : Sprite2D
var animation_player : AnimationPlayer

signal exploded

#used underscore to prevent conflict
func start(_position, _velocity, _size):
	sprite = $Sprite2D
	collision_shape = $CollisionShape2D
	animation_player = $Explosion/AnimationPlayer
	explosion_effect = $Explosion
	
	explosion_effect.scale = Vector2.ONE * 0.75 * _size
	
	position = _position
	size = _size
	mass = 1.5 * size
	sprite.scale = Vector2.ONE * scale_factor * size
	radius = int(sprite.texture.get_size().x / 2 * sprite.scale.x)
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var xform = state.transform
	xform.origin.x = wrapf(xform.origin.x, 0 - radius, screensize.x + radius)
	xform.origin.y = wrapf(xform.origin.y, 0 - radius, screensize.y + radius)
	state.transform = xform

func explode():
	collision_shape.set_deferred("disabled", true)
	$Sprite2D.hide()
	animation_player.play("explosion")
	explosion_effect.show()
	exploded.emit(size, radius, position, linear_velocity)
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	await animation_player.animation_finished
	queue_free()
	
	
	
	
	
	
	
	
	
