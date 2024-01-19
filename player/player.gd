extends RigidBody2D

@export var engine_power = 500
@export var spin_power = 8000
@export var bullet_scene : PackedScene
@export var fire_rate = 0.25

var can_shoot = true

var thrust = Vector2.ZERO
var rotation_dir = 0

enum StateEnum {INIT, ALIVE, INVULNERABLE, DEAD}
var state : StateEnum = StateEnum.INIT

var collision_shape : CollisionShape2D
var gun_cooldown : Timer
var muzzle : Marker2D

var screensize : Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screensize = get_viewport_rect().size
	collision_shape = $CollisionShape2D
	gun_cooldown = $GunCooldown
	muzzle = $Muzzle
	
	gun_cooldown.wait_time = fire_rate
	
	change_state(StateEnum.ALIVE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	get_input()

func _physics_process(delta: float) -> void:
	constant_force = thrust
	constant_torque = rotation_dir * spin_power

func _integrate_forces(physics_state: PhysicsDirectBodyState2D) -> void:
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screensize.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screensize.y)
	physics_state.transform = xform

func change_state(new_state : StateEnum):
	match new_state:
		StateEnum.INIT:
			collision_shape.set_deferred("disabled", true)
		StateEnum.ALIVE:
			collision_shape.set_deferred("disabled", false)
		StateEnum.INVULNERABLE:
			collision_shape.set_deferred("disabled", true)
		StateEnum.DEAD:
			collision_shape.set_deferred("disabled", true)

	state = new_state

func get_input():
	thrust = Vector2.ZERO
	
	if state in [StateEnum.DEAD, StateEnum.INIT]:
		return
	
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
	
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

func _on_gun_cooldown_timeout() -> void:
	can_shoot = true
