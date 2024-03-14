extends CanvasLayer

signal start_game

@onready var lives_counter : Array[Node] = $Control/MarginContainer/HBoxContainer/LivesCounter.get_children()
@onready var score_label : Label = $Control/MarginContainer/HBoxContainer/ScoreLabel
@onready var message : Label = $VBoxContainer/Message
@onready var start_button : TextureButton = $VBoxContainer/StartButton
@onready var timer : Timer = $Timer

func show_message(text):
	message.text = text
	message.show()
	timer.start()

func update_score(value):
	score_label.text = str(value)

func update_lives(value):
	for item in 3:
		lives_counter[item].visible = value > item

func game_over():
	show_message("Game Over")
	await timer.timeout
	start_button.show()

func _on_start_button_pressed() -> void:
	start_button.hide()
	start_game.emit()

func _on_timer_timeout() -> void:
	message.hide()
	message.text = ""
