extends Node

@export var rock_scene : PackedScene
@export var enemy_scene : PackedScene

var screensize: Vector2 = Vector2.ZERO

var rock_path : Path2D
var rock_spawn : PathFollow2D

var level: int    = 0
var score: int    = 0
var playing: bool = false

@onready var HUD : CanvasLayer = $HUD
@onready var player : RigidBody2D = $Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rock_path = $RockPath
	rock_spawn = $RockPath/RockSpawn
	screensize = get_viewport().get_visible_rect().size

func _process(delta: float) -> void:
	if not playing:
		return
	if get_tree().get_nodes_in_group("rocks").size() == 0:
		new_level()

func new_game():
	$Music.play()
	#remove any old rocks from the previous game
	get_tree().call_group("rocks", "queue_free")
	level = 0
	score = 0
	HUD.update_score(score)
	HUD.show_message("Get Ready!")
	player.reset()
	await $HUD/Timer
	playing = true

func new_level():
	$LevelUpSound.play()
	level += 1
	HUD.show_message("Wave %s" %level)
	for i in level:
		spawn_rock(3)
	$EnemyTimer.start(randf_range(5,10))

func spawn_rock(size, pos=null, vel=null):
	if pos == null:
		rock_spawn.progress = randi()
		pos = rock_spawn.position

	if vel == null:
		vel = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50,125)
		
	var r = rock_scene.instantiate()
	r.screensize = screensize
	r.start(pos, vel, size)
	call_deferred("add_child", r)
	r.exploded.connect(self._on_rock_exploded)
	
func _on_rock_exploded(size, radius, pos, vel):
	$ExplosionSound.play()
	if size <= 1:
		return
	for offset in [-1,1]:
		var dir = $Player.position.direction_to(pos).orthogonal() * offset
		var newpos = pos + dir * radius
		var newvel = dir * vel.length() * 1.1
		spawn_rock(size - 1, newpos, newvel)

func game_over():
	$Music.stop()
	playing = false
	HUD.game_over()

func _input(event):
	if event.is_action_pressed("pause"):
		if not playing:
			return
		get_tree().paused = not get_tree().paused
		var message = $HUD/VBoxContainer/Message
		if get_tree().paused:
			message.text = "Paused"
			message.show()
		else:
			message.text = ""
			message.hide()

func _on_enemy_timer_timeout():
	var e = enemy_scene.instantiate()
	add_child(e)
	e.target = $Player
	$EnemyTimer.start(randf_range(20,40))

