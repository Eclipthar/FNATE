extends AnimatedSprite2D
@onready var blip: AudioStreamPlayer = $"../blip"
@onready var disclaimer: TextureRect = $"../Disclaimer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set new game as default selection
	Global.is_newgame_selected = true
	Global.is_continue_selected = false
	self.animation = "newgame"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Check if disclaimer is showing - if so, only allow skipping it
	if Global.is_disclaimer_showing:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_select"):
			Global.is_disclaimer_showing = false
			disclaimer.visible = false  # Hide the disclaimer
		return  # Exit early, don't process menu inputs
	
	# Handle arrow key input
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
		blip.play()
		# Toggle between options
		Global.is_newgame_selected = !Global.is_newgame_selected
		Global.is_continue_selected = !Global.is_continue_selected
	
	# Handle Enter key to confirm selection
	if Input.is_action_just_pressed("ui_accept"):
		if Global.is_newgame_selected:
			get_tree().change_scene_to_file("res://game.tscn")
			# Add your new game logic here
		elif Global.is_continue_selected:
			get_tree().change_scene_to_file("res://game.tscn")
			# Add your continue logic here
	
	# Update animation based on selection
	if Global.is_continue_selected:
		self.animation = "continue"
	elif Global.is_newgame_selected:
		self.animation = "newgame"
