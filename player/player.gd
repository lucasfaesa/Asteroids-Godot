extends RigidBody2D

signal shield_changed(value : float)
signal lives_changed
signal dead

var reset_pos = false
var lives = 0 : set = set_lives

@export var engine_power = 500
@export var spin_power = 8000
@export var bullet_scene : PackedScene
@export var fire_rate = 0.25
@export var max_shield = 100.0
@export var shield_regen = 5.0

var shield = 0 : set = set_shield

var can_shoot = true

var thrust = Vector2.ZERO
var rotation_dir = 0

enum StateEnum {INIT, ALIVE, INVULNERABLE, DEAD}
var state : StateEnum = StateEnum.INIT

var collision_shape : CollisionShape2D
var gun_cooldown : Timer
var muzzle : Marker2D
var animationPlayer : AnimationPlayer

var screensize : Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screensize = get_viewport_rect().size
	collision_shape = $CollisionShape2D
	gun_cooldown = $GunCooldown
	muzzle = $Muzzle
	animationPlayer = $Explosion/AnimationPlayer
	animationPlayer.animation_finished.connect(explosion_animation_finished)
	
	gun_cooldown.wait_time = fire_rate
	
	change_state(StateEnum.ALIVE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	get_input()
	shield += shield_regen * delta


func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform
	
	if reset_pos:
		physics_state.transform.origin = screensize / 2
		reset_pos = false

func change_state(new_state : StateEnum):
	match new_state:
		StateEnum.INIT:
			collision_shape.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
		StateEnum.ALIVE:
			collision_shape.set_deferred("disabled", false)
			$Sprite2D.modulate.a = 1.0
		StateEnum.INVULNERABLE:
			collision_shape.set_deferred("disabled", true)
			$Sprite2D.modulate.a = 0.5
			$InvulnerabilityTimer.start()
		StateEnum.DEAD:
			collision_shape.set_deferred("disabled", true)
			$Sprite2D.hide()
			linear_velocity = Vector2.ZERO
			$EngineSound.stop()
			dead.emit()

	state = new_state

func get_input():
	$Exhaust.emitting = false
	thrust = Vector2.ZERO
	
	if state in [StateEnum.DEAD, StateEnum.INIT]:
		return
	
	if Input.is_action_pressed("thrust"):
		$Exhaust.emitting = true
		thrust = transform.x * engine_power
		if not $EngineSound.playing:
			$EngineSound.play()
	else:
		$EngineSound.stop()
	
	rotation_dir = Input.get_axis("rotate_left", "rotate_right")
	
	if(Input.is_action_pressed("shoot") and can_shoot):
		shoot()

func shoot():
	if state == StateEnum.INVULNERABLE:
		return
	can_shoot = false
	gun_cooldown.start()
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(muzzle.global_transform)
	$LaserSound.play()

func _on_gun_cooldown_timeout() -> void:
	can_shoot = true

func set_lives(value):
	shield = max_shield
	lives = value
	lives_changed.emit(lives)
	if lives <= 0:
		change_state(StateEnum.DEAD)
	else:
		change_state(StateEnum.INVULNERABLE)

func reset():
	reset_pos = true
	$Sprite2D.show()
	lives = 3
	change_state(StateEnum.ALIVE)


func _on_invulnerability_timer_timeout() -> void:
	change_state(StateEnum.ALIVE)

func set_shield(value):
	value = min(value, max_shield)
	shield = value
	shield_changed.emit(shield / max_shield)
	if shield <= 0:
		lives -= 1
		explode()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("rocks"):
		shield -= body.size * 25
		body.explode()

func explode():
	$Explosion.show()
	animationPlayer.play("explosion")

func explosion_animation_finished(anim_name : String):
	$Explosion.hide()















