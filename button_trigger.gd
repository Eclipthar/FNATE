extends Area2D

@onready var area: Area2D = self
var touching = false

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if touching == true:
				if Global.door_state == 1:
					Global.door_state = 0
					return
				if Global.door_state == 0:
					Global.door_state = 1
					return

func _on_mouse_entered() -> void:
	touching = true

func _on_mouse_exited() -> void:
	touching = false
