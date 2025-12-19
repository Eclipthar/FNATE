extends Control
@onready var disclaimer: TextureRect = $Disclaimer

func wait(seconds: float):
	await get_tree().create_timer(seconds).timeout

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disclaimer.visible = true
	disclaimer.modulate = Color.BLACK
	
	# Fade from black to white over 2 seconds
	var tween = create_tween()
	tween.tween_property(disclaimer, "modulate", Color.WHITE, 2.0)
	await tween.finished
	
	# Wait 3 seconds at full white
	await wait(5)

	disclaimer.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
