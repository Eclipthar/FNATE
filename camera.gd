extends Node2D

@onready var camera_pictures: AnimatedSprite2D = $AnimatedSprite2D
@onready var blip: AudioStreamPlayer = $"../blip"

func _ready() -> void:
	visible = false  # Start with this node (Camera) hidden

func _process(_delta: float) -> void:
	if Global.current_cam == 1:
		if Global.darkbear_location == 1:
			camera_pictures.frame = 1
		else:
			camera_pictures.frame = 0
			
	if Global.current_cam == 2:
		if Global.darkbear_location == 2:
			camera_pictures.frame = 3
		else:
			camera_pictures.frame = 2
			
	if Global.current_cam == 3:
		if Global.darkbear_location == 3:
			camera_pictures.frame = 5
		else:
			camera_pictures.frame = 4

func _on_button_pressed() -> void:
	Global.current_cam = 1
	blip.play()

func _on_button_2_pressed() -> void:
	Global.current_cam = 2
	blip.play()
	
func _on_button_3_pressed() -> void:
	Global.current_cam = 3
	blip.play()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("opencams"):
		visible = !visible  # Toggle visibility of this node
