extends Node2D

@onready var game_pictures: AnimatedSprite2D = $Sprite2D
@onready var camera_pictures: AnimatedSprite2D = $Camera/AnimatedSprite2D
@onready var camera: Node2D = $Camera

# Darkbear AI variables
var darkbear_activation_timer: float = 0.0
var darkbear_movement_timer: float = 0.0
var darkbear_is_active: bool = false

# Jumpscare timer variables
var office_stare_timer: float = 0.0
var camera_up_timer: float = 0.0
var is_jumpscared: bool = false

func _ready() -> void:
	print("=== GAME STARTED ===")
	# Initialize Darkbear
	Global.darkbear_location = 1  # Start at main stage
	Global.darkbear_AIlv = 3  # Set AI level for Night 3
	
	# Calculate activation time: 60 seconds / AI Level
	darkbear_activation_timer = 60.0 / Global.darkbear_AIlv
	darkbear_movement_timer = 0.0
	
	print("Darkbear AI Level: ", Global.darkbear_AIlv)
	print("Darkbear Starting Location: ", Global.darkbear_location, " (Main Stage)")
	print("Activation Time: ", darkbear_activation_timer, " seconds")
	print("Movement Check Interval: ", 10.0 / Global.darkbear_AIlv, " seconds")
	print("===================")

func _process(delta: float) -> void:
	# If already jumpscared, don't process anything else
	if is_jumpscared:
		return
	
	# Update office sprite based on Darkbear location and power status
	update_office_sprite()
	
	# Handle Darkbear activation
	if not darkbear_is_active:
		darkbear_activation_timer -= delta
		
		# Debug: Show countdown every second
		if int(darkbear_activation_timer) != int(darkbear_activation_timer + delta):
			print("[WAITING] Darkbear activates in: ", int(darkbear_activation_timer), " seconds")
		
		if darkbear_activation_timer <= 0:
			print("*** DARKBEAR ACTIVATED! ***")
			darkbear_is_active = true
			darkbear_move_darkbear()  # 100% chance to move on activation
	
	# Handle Darkbear movement after activation
	if darkbear_is_active:
		darkbear_movement_timer += delta
		var movement_interval = 10.0 / Global.darkbear_AIlv
		
		if darkbear_movement_timer >= movement_interval:
			darkbear_movement_timer = 0.0
			print("[CHECK] Movement check triggered!")
			darkbear_attempt_move()
	
	# Handle jumpscare mechanics when Darkbear is in office
	if Global.darkbear_location == 4:
		handle_office_jumpscare_mechanics(delta)

func handle_office_jumpscare_mechanics(delta: float) -> void:
	# Check if camera is up using the camera node's visibility
	var camera_is_up = camera.visible
	
	if camera_is_up:
		# Reset office stare timer when camera is up
		office_stare_timer = 0.0
		
		# Increment camera up timer
		camera_up_timer += delta
		
		# Debug print every second
		if int(camera_up_timer) != int(camera_up_timer - delta):
			print("[CAMERA UP] Player has camera up for ", int(camera_up_timer), " seconds (jumpscare at 10)")
		
		# If camera has been up for more than 10 seconds, trigger jumpscare
		if camera_up_timer >= 10.0:
			print("!!! CAMERA TIMEOUT JUMPSCARE !!! Player kept cameras up too long!")
			trigger_jumpscare()
	else:
		# Reset camera up timer when camera is down
		camera_up_timer = 0.0
		
		# Increment office stare timer
		office_stare_timer += delta
		
		# Debug print
		if office_stare_timer > 0 and int(office_stare_timer * 10) != int((office_stare_timer - delta) * 10):
			print("[STARING] Player staring at Darkbear for ", office_stare_timer, " seconds (jumpscare at 1.0)")
		
		# If player has been staring at Darkbear for more than 1 second, trigger jumpscare
		if office_stare_timer >= 1.0:
			print("!!! STARE JUMPSCARE !!! Player looked at Darkbear too long!")
			trigger_jumpscare()

func trigger_jumpscare() -> void:
	is_jumpscared = true
	game_pictures.frame = 4  # Jumpscare frame
	camera.visible = false  # Force camera down
	print(">>> GAME OVER - JUMPSCARED <<<")
	# You can add additional jumpscare effects here (sound, animation, scene change, etc.)

func update_office_sprite() -> void:
	var power_out = false  # You'll need to add this to Global or track it here
	var old_frame = game_pictures.frame
	
	if Global.darkbear_location == 4:  # Darkbear in office
		if power_out:
			game_pictures.frame = 2  # In office + power out
		else:
			game_pictures.frame = 1  # In office + power on
	else:  # Darkbear not in office
		if power_out:
			game_pictures.frame = 3  # Not in office + power out
		else:
			game_pictures.frame = 0  # Not in office + power on
	
	# Debug: Only print when frame changes
	if old_frame != game_pictures.frame:
		print("[SPRITE] Office frame changed: ", old_frame, " -> ", game_pictures.frame)

func darkbear_attempt_move() -> void:
	# 25% (1/4) chance to move
	var roll = randf()
	print("  [ROLL] Movement roll: ", roll, " (needs < 0.25 to move)")
	
	if roll < 0.25:
		print("  [SUCCESS] Movement succeeded!")
		darkbear_move_darkbear()
	else:
		print("  [FAIL] Movement failed, Darkbear stays at location ", Global.darkbear_location)

func darkbear_move_darkbear() -> void:
	var old_location = Global.darkbear_location
	var location_names = {
		1: "Main Stage",
		2: "Party Room",
		3: "Play Room",
		4: "Office"
	}
	
	# Movement path: 1 (Main Stage) -> 2 (Party Room) -> 3 (Play Room) -> 4 (Office)
	match Global.darkbear_location:
		1:  # Main Stage
			Global.darkbear_location = 2  # Move to Party Room
		2:  # Party Room
			Global.darkbear_location = 3  # Move to Play Room
		3:  # Play Room
			Global.darkbear_location = 4  # Move to Office
			print(">>> DARKBEAR REACHED OFFICE! Player must use cameras or will be jumpscared! <<<")
		4:  # Office (should not happen with new logic)
			trigger_jumpscare()
			return
	
	print(">>> DARKBEAR MOVED: ", location_names[old_location], " (", old_location, ") -> ", location_names[Global.darkbear_location], " (", Global.darkbear_location, ") <<<")
