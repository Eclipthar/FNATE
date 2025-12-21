extends Node2D

@onready var game_pictures: AnimatedSprite2D = $Sprite2D
@onready var camera_pictures: AnimatedSprite2D = $Camera/AnimatedSprite2D
@onready var camera: Node2D = $Camera
@onready var scare: AudioStreamPlayer = $scare
@onready var jumpscare: AudioStreamPlayer = $jumpscare
@onready var powerdown: AudioStreamPlayer = $powerdown
@onready var shock: AudioStreamPlayer = $shock

# Darkbear AI variables
var darkbear_activation_timer: float = 0.0
var darkbear_movement_timer: float = 0.0
var darkbear_is_active: bool = false

# Jumpscare timer variables
var office_stare_timer: float = 0.0
var camera_up_timer: float = 0.0
var is_jumpscared: bool = false

# Shock system variables
var shock_cooldown: float = 0.0
var shock_ready: bool = true
const SHOCK_COOLDOWN_TIME: float = 5.0  # Seconds before shock is ready again
var shock_flash_timer: float = 0.0
var is_shock_flashing: bool = false

# Power outage variables
var power_out_timer: float = 0.0
var is_power_out: bool = false
var power_flicker_timer: float = 0.0
var power_flicker_state: bool = false  # false = frame 3, true = frame 2

# Window shake variables
var is_shaking: bool = false
const SHAKE_DURATION: float = 5.0
const SHAKE_INTENSITY: int = 500

# Konami code variables
var konami_sequence: Array = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_input: Array = []

# Location connection map - defines which locations can be reached from each location
var location_connections = {
	1: [2, 3],      # Main Stage -> Party Room OR Play Room
	2: [1, 3],      # Party Room -> Main Stage OR Play Room
	3: [1, 2, 4],   # Play Room -> Main Stage OR Party Room OR Office
	4: []           # Office has no exits (player must shock or get jumpscared)
}

func _ready() -> void:
	print("=== GAME STARTED ===")
	# Initialize Darkbear
	Global.darkbear_location = 1  # Start at main stage
	Global.darkbear_AIlv = 3  # Set AI level for Night 3
	
	# Calculate activation time: 60 seconds / AI Level
	darkbear_activation_timer = 60.0 / Global.darkbear_AIlv
	darkbear_movement_timer = 0.0
	
	# Set camera_static to loop if it exists
	if camera.has_node("../camera_static"):
		var camera_static = camera.get_node("../camera_static")
		if camera_static.stream:
			camera_static.stream.loop = true
	
	print("Darkbear AI Level: ", Global.darkbear_AIlv)
	print("Darkbear Starting Location: ", Global.darkbear_location, " (Main Stage)")
	print("Activation Time: ", darkbear_activation_timer, " seconds")
	print("Movement Check Interval: ", 10.0 / Global.darkbear_AIlv, " seconds")
	print("CONTROLS: Press SPACE to use shock system")
	print("SECRET: Try the Konami code!")
	print("===================")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # SPACE key (default for ui_accept)
		use_shock()
	
	# Konami code detection
	if event is InputEventKey and event.pressed and not event.echo:
		var key_name = ""
		
		# Map keys to konami sequence names
		if event.keycode == KEY_UP:
			key_name = "up"
		elif event.keycode == KEY_DOWN:
			key_name = "down"
		elif event.keycode == KEY_LEFT:
			key_name = "left"
		elif event.keycode == KEY_RIGHT:
			key_name = "right"
		elif event.keycode == KEY_B:
			key_name = "b"
		elif event.keycode == KEY_A:
			key_name = "a"
		
		# If a valid konami key was pressed
		if key_name != "":
			konami_input.append(key_name)
			
			# Keep only the last 10 inputs
			if konami_input.size() > 10:
				konami_input.pop_front()
			
			# Check if konami code is complete
			if konami_input == konami_sequence:
				print(">>> KONAMI CODE ACTIVATED! DARKBEAR TELEPORTED TO OFFICE! <<<")
				Global.darkbear_location = 4
				darkbear_is_active = true
				scare.play()
				konami_input.clear()  # Reset after activation

func _process(delta: float) -> void:
	# If already jumpscared, don't process anything else
	if is_jumpscared:
		return
	
	# Check for power outage
	check_power_status()
	
	# Handle power outage sequence
	if is_power_out:
		handle_power_outage(delta)
		return  # Don't process normal game logic during power outage
	
	# Handle shock flash effect
	if is_shock_flashing:
		shock_flash_timer -= delta
		if shock_flash_timer <= 0:
			is_shock_flashing = false
			print("[SHOCK] Flash effect ended")
		update_office_sprite()
		return  # Don't update sprite normally during flash
	
	# Update shock cooldown
	if not shock_ready:
		shock_cooldown -= delta
		if shock_cooldown <= 0:
			shock_ready = true
			print("[SHOCK] Shock system recharged and ready!")
	
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
	
	# Handle jumpscare mechanics when Darkbear is in office (only if power is on)
	if Global.darkbear_location == 4 and not is_power_out:
		handle_office_jumpscare_mechanics(delta)

func check_power_status() -> void:
	# Check if power has run out
	if Global.PowerLV <= 0 and not is_power_out:
		print("!!! POWER OUT !!!")
		powerdown.play()  # Play power down sound
		is_power_out = true
		power_out_timer = 0.0
		camera.visible = false  # Force cameras down
		print("[POWER] Power depleted! Darkbear will arrive in 10 seconds...")

func handle_power_outage(delta: float) -> void:
	power_out_timer += delta
	
	# Phase 1: First 10 seconds - just dark (frame 3)
	if power_out_timer < 10.0:
		game_pictures.frame = 3  # Power out, no Darkbear yet
		
		# Debug every second
		if int(power_out_timer) != int(power_out_timer - delta):
			print("[POWER] Darkbear arrives in ", int(10 - power_out_timer), " seconds...")
	
	# Phase 2: Darkbear appears at 10 seconds
	elif power_out_timer >= 10.0 and Global.darkbear_location != 4:
		print(">>> DARKBEAR APPEARED IN OFFICE DUE TO POWER OUTAGE! <<<")
		Global.darkbear_location = 4
		power_flicker_timer = 0.0
	
	# Phase 3: Next 10 seconds - flicker between frames 2 and 3
	if power_out_timer >= 10.0 and power_out_timer < 20.0:
		power_flicker_timer += delta
		
		# Flicker every 0.3 seconds for creepy effect
		if power_flicker_timer >= 0.3:
			power_flicker_timer = 0.0
			power_flicker_state = not power_flicker_state
			
			if power_flicker_state:
				game_pictures.frame = 2  # Power out WITH Darkbear visible
			else:
				game_pictures.frame = 3  # Power out WITHOUT Darkbear visible
		
		# Debug every second
		if int(power_out_timer - 10.0) != int(power_out_timer - 10.0 - delta):
			print("[POWER] Jumpscare in ", int(20 - power_out_timer), " seconds...")
	
	# Phase 4: After 20 seconds total - JUMPSCARE
	elif power_out_timer >= 20.0:
		print("!!! POWER OUTAGE JUMPSCARE !!!")
		trigger_jumpscare()

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
	jumpscare.play()  # Play jumpscare sound
	print(">>> GAME OVER - JUMPSCARED <<<")
	
	# Start window shake effect and wait for it to complete
	await start_window_shake()
	
	# Return to main menu after shake
	print("[JUMPSCARE] Returning to main menu...")
	get_tree().change_scene_to_file("res://mainmenu.tscn")

func use_shock() -> void:
	"""Call this function when player presses the shock button"""
	if not shock_ready:
		print("[SHOCK] Shock on cooldown! ", shock_cooldown, " seconds remaining")
		return
	
	if Global.darkbear_location == 4:
		print("[SHOCK] *** SHOCK ACTIVATED! Darkbear sent back to Main Stage! ***")
		shock.play()  # Play shock sound effect
		Global.darkbear_location = 1
		office_stare_timer = 0.0
		camera_up_timer = 0.0
		
		# Start shock flash effect (frame 3 for 4 seconds)
		is_shock_flashing = true
		shock_flash_timer = 4.0
		print("[SHOCK] Shock flash effect started (4 seconds)")
		
		# Start cooldown
		shock_ready = false
		shock_cooldown = SHOCK_COOLDOWN_TIME
		print("[SHOCK] Shock on cooldown for ", SHOCK_COOLDOWN_TIME, " seconds")
		
		# Update sprite immediately to frame 3
		game_pictures.frame = 3
	else:
		print("[SHOCK] Shock wasted! Darkbear is not in the office (location: ", Global.darkbear_location, ")")
		shock.play()  # Play shock sound even when wasted
		# Still trigger cooldown even if wasted
		shock_ready = false
		shock_cooldown = SHOCK_COOLDOWN_TIME

func update_office_sprite() -> void:
	var old_frame = game_pictures.frame
	
	# If shock flash is active, keep it at frame 3
	if is_shock_flashing:
		game_pictures.frame = 3
		return
	
	# If power is out, don't update sprite here (handled in power outage function)
	if is_power_out:
		return
	
	# Normal sprite update logic
	if Global.darkbear_location == 4:  # Darkbear in office
		game_pictures.frame = 1  # In office + power on
	else:  # Darkbear not in office
		game_pictures.frame = 0  # Not in office + power on
	
	# Debug: Only print when frame changes
	if old_frame != game_pictures.frame:
		print("[SPRITE] Office frame changed: ", old_frame, " -> ", game_pictures.frame)

func darkbear_attempt_move() -> void:
	# Don't attempt movement if Darkbear is in office (he stays until shocked or jumpscare)
	if Global.darkbear_location == 4:
		return
	
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
	
	# Get possible destinations from current location
	var possible_moves = location_connections[Global.darkbear_location]
	
	if possible_moves.size() == 0:
		print("[ERROR] No valid moves from location ", Global.darkbear_location)
		return
	
	# Randomly choose one of the possible destinations
	var new_location = possible_moves[randi() % possible_moves.size()]
	Global.darkbear_location = new_location
	
	# Special message and sound if entering office
	if Global.darkbear_location == 4:
		scare.play()  # Play scare sound only when entering office
		print(">>> DARKBEAR REACHED OFFICE! Use shock to send him away or get jumpscared! <<<")
	
	print(">>> DARKBEAR MOVED: ", location_names[old_location], " (", old_location, ") -> ", location_names[Global.darkbear_location], " (", Global.darkbear_location, ") <<<")
	print("    Possible next moves from location ", Global.darkbear_location, ": ", location_connections[Global.darkbear_location])

func start_window_shake() -> void:
	if is_shaking:
		return
	
	is_shaking = true
	var window = get_window()
	var original_pos = window.position
	
	# Simple timer-based approach
	var elapsed := 0.0
	
	while elapsed < SHAKE_DURATION:
		var shake_x = randi_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		var shake_y = randi_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		window.position = original_pos + Vector2i(shake_x, shake_y)
		
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	
	# Restore original position
	window.position = original_pos
	is_shaking = false
	print("[SHAKE] Window shake complete!")
