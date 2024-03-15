extends Area2D

@export var bullet_scene : PackedScene
@export var speed : int = 150
@export var rotation_speed : int = 120
@export var health : int = 3

var follow : PathFollow2D = PathFollow2D.new()
var target = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.frame = randi() % 3
	var path = $EnemyPaths.get_children()[randi() % $EnemyPaths.get_child_count()]
	path.add_child(follow)
	follow.loop = false

func _physics_process(delta: float) -> void:
	rotation += deg_to_rad(rotation_speed) * delta
	follow.progress += speed * delta
	position = follow.global_position
	if follow.progress_ratio >= 1:
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_gun_cooldown_timeout() -> void:
	pass # Replace with function body.