extends Area2D

@export var bullet_scene : PackedScene
@export var speed : int = 150
@export var rotation_speed : int = 120
@export var health : int = 3
@export var bullet_spread : float = 0.2

var follow : PathFollow2D = PathFollow2D.new()
var target = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.frame = randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	path.add_child(follow)
	follow.loop = false
	$Explosion/AnimationPlayer.animation_finished.connect(explosion_animation_finished)

func _physics_process(delta: float) -> void:
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position
	if follow.progress_ratio >= 1:
		queue_free()

func shoot():
	$ShootSound.play()
	var dir = global_position.direction_to(target.global_position)
	dir = dir.rotated(randf_range(-bullet_spread, bullet_spread))
	var b = bullet_scene.instantiate()
	get_tree().root.add_child(b)
	b.start(global_position, dir)

func shoot_pulse(n, delay):
	for i in n:
		shoot()
		await get_tree().create_timer(delay).timeout

func _on_gun_cooldown_timeout() -> void:
	var random_number : int = randi_range(0,1)
	match random_number:
		0:
			shoot()
		1:
			shoot_pulse(randi_range(1, 3), randf_range(0.6, 1))

func take_damage(amount : int):
	health -= amount
	$AnimationPlayer.play("flash")
	if health <= 0:
		explode()

func explode():
	$ExplosionSound.play()
	speed = 0
	$GunCooldown.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion/AnimationPlayer.play("explosion")

func explosion_animation_finished(anim_name : String):
	queue_free()

func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("rocks"):
		return
	explode()
	body.shield -= 50
