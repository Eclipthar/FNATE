extends Control
@onready var disclaimer: TextureRect = $Disclaimer
func wait(seconds: float):
	await get_tree().create_timer(seconds).timeout
	
@onready var mainbear_1: Sprite2D = $Mainbear1


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

# Add your different sprite textures here
var bear_sprites: Array[Texture2D] = []
var default_sprite: Texture2D
var twitch_timer: float = 0.0
var twitch_interval: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disclaimer.visible = true
	disclaimer.modulate = Color.BLACK
	
	# Save the default sprite automatically
	default_sprite = mainbear_1.texture
	
	# Fade from black to white over 2 seconds
	var tween = create_tween()
	tween.tween_property(disclaimer, "modulate", Color.WHITE, 2.0)
	await tween.finished
	
	# Wait 3 seconds at full white
	await wait(5)
	disclaimer.visible = false
	
	# Load your bear sprite variations (add your texture paths)
	bear_sprites.append(preload("res://Textures/mainbear1.png"))
	bear_sprites.append(preload("res://Textures/mainbear2.png"))
	bear_sprites.append(preload("res://Textures/mainbear3.png"))
	bear_sprites.append(preload("res://Textures/mainbear4.png"))
	
	# Set initial random interval
	twitch_interval = randf_range(3.0, 7.0)
	
	Global.is_disclaimer_showing = true
	# Nights
	Global.is_dead = false
	Global.power_out = false
	Global.PowerLV = 100
	# Main Menu
	Global.is_continue_selected = false
	Global.is_newgame_selected = true
	# Dark bear
	Global.darkbear_AIlv = 3  # Default AI level
	Global.darkbear_location = 1  # Default starting location
	# Camera
	Global.current_cam = 0  # Default camera

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	twitch_timer += delta
	
	if twitch_timer >= twitch_interval:
		twitch_bear()
		twitch_timer = 0.0
		# Set new random interval between 3 and 7 seconds (average ~5)
		twitch_interval = randf_range(3.0, 5.0)

func twitch_bear() -> void:
	if bear_sprites.size() == 0:
		return
	
	# Change to random sprite variant
	var random_sprite = bear_sprites[randi() % bear_sprites.size()]
	mainbear_1.texture = random_sprite
	
	# Wait a brief moment (twitch duration)
	await wait(randf_range(0.01, 0.22))
	
	# Reset back to default sprite
	mainbear_1.texture = default_sprite
